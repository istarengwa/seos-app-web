require "rails_helper"

RSpec.describe AppFeatures do
  let(:actor) { create(:user, :super_admin) }
  def switch(key, enabled)
    described_class.change!(actor: actor, key: key, enabled: enabled, reason: "Préparation du lancement", expected: described_class.digest, password: "UnMotDePasseSolide!42")
  end

  it "conserve les données et le réglage des dépendances au fil des désactivations" do
    organization = organization_space
    mission = world_mission(organization: organization)
    snapshot = [ organization.attributes, mission.attributes ]
    switch("associations", false)
    expect(described_class.enabled?("associations")).to be(false)
    expect(described_class.enabled?("voyage")).to be(false)
    expect(FeatureFlag.find_by(key: "voyage_enabled")).to be_nil
    switch("associations", true)
    expect(described_class.enabled?("voyage")).to be(true)
    switch("voyage", false)
    switch("associations", false)
    switch("associations", true)
    expect(described_class.enabled?("voyage")).to be(false)
    expect([ organization.reload.attributes, mission.reload.attributes ]).to eq(snapshot)
    expect(AuditLog.where(action: "feature.change").count).to eq(5)
  end

  it "refuse les pertes de mise à jour et journalise uniquement les changements effectifs" do
    digest = described_class.digest
    switch("chains", false)
    expect do
      described_class.change!(actor: actor, key: "chains", enabled: true, reason: "Ancien écran", expected: digest)
    end.to raise_error(Exchanges::Invalid, /ont changé/)
    expect { switch("chains", false) }.not_to change(AuditLog, :count)
    flag = FeatureFlag.find_by!(key: "chains_enabled")
    cutoff = flag.disabled_at
    switch("chains", true)
    expect(flag.reload.disabled_at).to eq(cutoff)
    expect(AuditLog.last.metadata).to eq("feature" => "chains", "from" => "disabled", "to" => "enabled")
  end

  it "réserve les interrupteurs au super admin et protège les points et les annonces" do
    admin = create(:user, :admin)
    expect { described_class.change!(actor: admin, key: "chains", enabled: false, reason: "Essai", expected: described_class.digest) }.to raise_error(Pundit::NotAuthorizedError)
    %w[points listings unknown].each do |key|
      expect { switch(key, false) }.to raise_error(Exchanges::Invalid, /inconnue/)
    end
    [ "", "a" * 501, nil ].each do |reason|
      expect { described_class.change!(actor: actor, key: "chains", enabled: false, reason: reason, expected: described_class.digest) }.to raise_error(Exchanges::Invalid)
    end
    expect { described_class.change!(actor: actor, key: "chains", enabled: nil, reason: "Essai", expected: described_class.digest) }.to raise_error(Exchanges::Invalid)
    expect { described_class.change!(actor: actor, key: "google_login", enabled: false, reason: "Essai", expected: described_class.digest, password: "incorrect") }.to raise_error(Exchanges::Invalid, /mot de passe/)
    expect(described_class.enabled?("google_login")).to be(true)
    switch("google_login", false)
    expect(described_class.enabled?("google_login")).to be(false)
  end

  it "bloque les services métier directement sans bloquer les points, les annonces ou les demandes de données" do
    point_rules
    member = create(:profile).user
    chain_rule = ChainRuleVersion.create!(name: "Chaîne", effective_at: 2.days.ago, status: "published", length_mode: "unlimited", max_links: nil, points_per_validation: 5, max_points_per_link: 10, max_points_per_member: 30, reward_scope: "provider_only", rewarded_previous_links: 1)
    AppFeatures::DEFINITIONS.each_key { |key| switch(key, false) }
    expect { Chains.create!(actor: member, name: "Nouvelle chaîne") }.to raise_error(Exchanges::Invalid, /désactivée/)
    expect { Achievements.submit!(user: member, achievement: nil, evidence: "Preuve") }.to raise_error(Exchanges::Invalid, /désactivée/)
    expect { OrganizationWorkflow.create!(actor: member, attributes: {}) }.to raise_error(Exchanges::Invalid, /désactivée/)
    expect { Missions.apply!(mission: nil, actor: member, message: "Aider", starts_on: Date.current, ends_on: Date.current) }.to raise_error(Exchanges::Invalid, /désactivée/)
    expect { Community.testimonial!(user: member, attributes: {}, consent: "1") }.to raise_error(Exchanges::Invalid, /désactivée/)
    expect { Community.request_top!(user: member, listing: nil) }.to raise_error(Exchanges::Invalid, /désactivée/)
    expect { Referrals.link_for!(member) }.to raise_error(Exchanges::Invalid, /désactivée/)
    expect { GoogleIdentity.resolve!(auth: nil) }.to raise_error(Exchanges::Invalid, /désactivée/)
    expect { Points::Rewards.welcome!(member) }.to change { PointAccount.for!(member).reload.balance }.by(30)
    listing = create(:listing, user: member)
    expect(listing).to be_publicly_visible
    expect { Privacy.request!(user: member, kind: "access", details: "Mes données") }.to change(DataRequest, :count).by(1)
    expect(chain_rule.reload.status).to eq("published")
    expect(Referrals.register_link!(member, 999)).to be_nil
    expect(Referrals.activate_pending!(member)).to be_nil
    expect(Referrals.mature!).to be_nil
  end

  it "suspend les notifications optionnelles sans supprimer celles qui existent ni renvoyer les anciennes" do
    member = create(:user)
    old = Notification.notify!(user: member, key: "chain:old", title: "Une chaîne vous attend")
    core = Notification.notify!(user: member, key: "points:kept", title: "Vos points")
    travel 2.seconds do
      switch("chains", false)
      expect(Notification.feature_visible).not_to include(old)
      expect(Notification.feature_visible).to include(core)
      expect { Notification.notify!(user: member, key: "chain:disabled", title: "Masqué") }.not_to change(Notification, :count)
      expect(described_class.notice_allowed?(old)).to be(false)
      switch("chains", true)
      expect(described_class.notice_allowed?(old)).to be(false)
      expect(Notification.find(old.id)).to eq(old)
    end
    travel 4.seconds do
      fresh = Notification.notify!(user: member, key: "chain:fresh", title: "Une nouvelle chaîne")
      expect(described_class.notice_allowed?(fresh)).to be(true)
      expect(described_class.notice_allowed?(core)).to be(true)
    end
  end

  it "rend les quêtes dépendantes indisponibles tout en gardant les autres quêtes" do
    chain = Achievement.new(reward_key: "chain")
    referral = Achievement.new(reward_key: "referral")
    video = Achievement.new(reward_key: "video")
    listing = Achievement.new(reward_key: "listing")
    %w[chains referrals testimonials].each { |key| switch(key, false) }
    [ chain, referral, video ].each { |quest| expect(described_class.quest_available?(quest)).to be(false) }
    expect(described_class.quest_available?(listing)).to be(true)
    described_class::DEFINITIONS.each_key { |key| expect(described_class.impact(key)).to be_a(Hash) }
    expect(described_class.impact("unknown")).to eq({})
  end
end
