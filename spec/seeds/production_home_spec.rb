require "rails_helper"

RSpec.describe "Accueil initial en production" do
  before { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production")) }

  it "crée seulement l’accueil publié, sans compte ni données de démonstration" do
    expect { load Rails.root.join("db/seeds.rb") }.not_to have_enqueued_job
    version = StudioVersion.current
    expect(version).to be_system_generated
    expect(version.author).to be_nil
    expect(version.site).to eq("pages" => { "home" => SiteDesign.home_page })
    expect(version.validated_digest).to eq(version.digest)
    expect(SeedRun.find_by!(name: "production_home").completed_at).to be_present
    [ User, Profile, Listing, Organization, VolunteerMission, ContentVersion, AuditLog, Achievement, PointRuleVersion, PointAccount, ReviewCriterion, FeatureFlag, ActiveStorage::Blob ].each do |model|
      expect(model.count).to eq(0), "La seed de production ne doit pas créer de #{model.name}"
    end
  end

  it "préserve les modifications ultérieures et ne recrée jamais un accueil supprimé" do
    load Rails.root.join("db/seeds.rb")
    admin = create(:user, :super_admin)
    initial = StudioVersion.current
    settings = initial.settings.deep_dup
    settings["site"]["pages"]["home"]["blocks"].first["values"]["text-1"] = "Notre accueil personnalisé"
    custom = Studio.change!(actor: admin, source: initial, settings: settings, name: "Accueil personnalisé")
    Studio.publish_from_review!(version: custom, actor: admin, digest: custom.digest, live_id: initial.id)
    marker = SeedRun.find_by!(name: "production_home").completed_at
    expect { 2.times { load Rails.root.join("db/seeds.rb") } }.not_to change(StudioVersion, :count)
    expect(StudioVersion.current).to eq(custom)
    expect(custom.reload.settings).to eq(settings)
    StudioVersion.delete_all
    expect { load Rails.root.join("db/seeds.rb") }.not_to change(StudioVersion, :count)
    expect(SeedRun.find_by!(name: "production_home").completed_at).to eq(marker)
  end

  it "annule le marqueur si l’initialisation échoue et permet une reprise complète" do
    allow(StudioVersion).to receive(:new).and_raise("Initialisation interrompue")
    expect { load Rails.root.join("db/seeds.rb") }.to raise_error("Initialisation interrompue")
    expect(SeedRun.count).to eq(0)
    allow(StudioVersion).to receive(:new).and_call_original
    load Rails.root.join("db/seeds.rb")
    expect(StudioVersion.current).to be_present
    expect { PointRewardsJob.perform_later(123) }.to have_enqueued_job(PointRewardsJob)
  end
end
