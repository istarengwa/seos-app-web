require "rails_helper"

RSpec.describe "Conservation depuis le Studio", type: :request do
  let(:author) { create(:user, :super_admin) }
  let(:rules) { RetentionPolicyVersion::PURPOSES.index_with { |purpose| purpose == "exports" ? 1 : 90 } }
  let(:proposal) { { operation: "policy", name: "Durées du collectif", rules: rules, effective_at: 1.day.from_now, expires_at: 1.year.from_now, legal_reviewed: "1" } }

  it "prépare et simule dans le Studio puis exige un autre administrateur pour confirmer" do
    login author
    post admin_privacy_index_path, params: proposal, as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("html")).to include("Durées du collectif", "Notifications", "90 jours")
    policy = RetentionPolicyVersion.last
    expect(policy.status).to eq("draft")
    post admin_privacy_index_path, params: { operation: "simulate", record_id: policy.id, reason: "Vérification des durées" }, as: :json
    expect(response).to have_http_status(:ok)
    expect(policy.reload.status).to eq("simulated")
    post admin_privacy_index_path, params: { operation: "publish", record_id: policy.id, reason: "Même auteur" }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(policy.reload.status).to eq("simulated")
    delete destroy_user_session_path
    approver = create(:user, :super_admin)
    login approver
    post admin_privacy_index_path, params: { operation: "publish", record_id: policy.id, reason: "Revue terminée" }, as: :json
    expect(response).to have_http_status(:ok)
    expect(policy.reload).to have_attributes(status: "published", approved_by: approver, rules: rules)
    expect(AuditLog.where(target: policy, action: "privacy.policy.publish", actor: approver)).to exist
  end

  it "conserve les contrôles sur les durées et les permissions avant toute mutation" do
    login author
    expect do
      post admin_privacy_index_path, params: proposal.merge(rules: rules.merge("exports" => 2)), as: :json
    end.not_to change { [ RetentionPolicyVersion.count, AuditLog.count ] }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.fetch("error")).to include("1 jour")
    delete destroy_user_session_path
    moderator = create(:user, :admin)
    grant(moderator, "privacy.rules")
    login moderator
    expect { post admin_privacy_index_path, params: proposal, as: :json }.not_to change(RetentionPolicyVersion, :count)
    expect(response).to have_http_status(:forbidden)
  end

  it "conserve le traitement des demandes dans la vue d’ensemble et retire les liens d’édition en double" do
    member = create(:profile, display_name: "Camille Données").user
    request = Privacy.request!(user: member, kind: "rectification", details: "Corriger mon profil")
    moderator = create(:user, :admin)
    grant(moderator, "privacy.manage")
    login moderator
    get admin_root_path(tab: "data")
    expect(response.body).to include("Camille Données", "Corriger mon profil")
    post admin_privacy_index_path, params: { operation: "review", record_id: request.id, response: "Correction examinée" }
    expect(response).to redirect_to(admin_root_path(tab: "data"))
    expect(request.reload.status).to eq("reviewed")
    post admin_privacy_index_path, params: { operation: "review", record_id: request.id, response: "Correction confirmée" }, as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq("message" => "Demande mise à jour.")
    delete destroy_user_session_path
    login author
    get legal_center_path
    expect(Nokogiri::HTML(response.body).at_css('#legal-cgu .legal-edit-action a')["href"]).to eq(admin_site_index_path(page: "legal", document: "cgu"))
    get admin_site_index_path(page: "legal", document: "cookies", panel: "retention")
    follow_redirect!
    expect(response.body).to include('data-studio-retention', 'data-open-on-load')
    expect(studio_builder_configuration["legalDocument"]).to eq("cookies")
  end
end
