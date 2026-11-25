require "rails_helper"
RSpec.describe "Délégations et garde-fous de la phase 7", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:super_admin) { create(:user, :super_admin) }
  let(:user) { create(:user) }
  it "refuse les espaces sans droit et dissocie conservation et demandes" do
    login admin
    [ admin_privacy_index_path, admin_site_index_path, admin_operations_path ].each do |path|
      get path
      expect(response).to have_http_status(:forbidden)
    end
    grant(admin, "privacy.manage")
    get admin_privacy_index_path
    expect(response).to redirect_to(admin_root_path(tab: "data"))
    follow_redirect!
    expect(response.body).to include("Demandes de données personnelles")
    expect(response.body).not_to include("Nouvelle politique")
    post admin_privacy_index_path, params: { operation: "policy", rules: "{}" }
    expect(response).to have_http_status(:forbidden)
    admin.admin_permission_grants.update_all(revoked_at: Time.current)
    grant(admin, "privacy.rules")
    get admin_privacy_index_path
    expect(response).to redirect_to(admin_root_path(tab: "tools"))
    task = ProviderErasureTask.create!(data_request: Privacy.request!(user: user, kind: "erasure", details: ""), provider: "google")
    post admin_privacy_index_path, params: { operation: "provider", record_id: task.id, response: "OK", reason: "Validation" }
    expect(response).to have_http_status(:forbidden)
  end
  it "audite la confirmation prestataire et les erreurs de traitement" do
    record = Privacy.request!(user: user, kind: "access", details: "")
    task = ProviderErasureTask.create!(data_request: record, provider: "backups")
    login super_admin
    post admin_privacy_index_path, params: { operation: "provider", record_id: task.id }
    expect(response).to have_http_status(:unprocessable_content)
    post admin_privacy_index_path, params: { operation: "provider", record_id: task.id, response: "Expiration vérifiée", reason: "Contrôle" }
    expect(task.reload.status).to eq("completed")
    post admin_privacy_index_path, params: { operation: "export", record_id: record.id }
    expect(record.reload).to be_export_available
    post admin_privacy_index_path, params: { operation: "execute", record_id: record.id }
    expect(response).to have_http_status(:unprocessable_content)
    post admin_privacy_index_path, params: { operation: "preview_purge", reason: "Test" }
    expect(response).to have_http_status(:unprocessable_content)
    post admin_privacy_index_path, params: { operation: "invalid" }
    expect(response).to have_http_status(:unprocessable_content)
    post account_privacy_path, params: { kind: "rectification", details: "Corriger mon profil" }
    expect(DataRequest.last.kind).to eq("rectification")
  end
  it "exécute une suspension après seconde validation et contrôle les blocages" do
    grant(admin, "operations.manage")
    login admin
    post admin_operations_path, params: { operation: "preview", ids: user.id, reason: "Abus" }
    expect(response).to have_http_status(:forbidden)
    delete destroy_user_session_path
    preparer = create(:user, :super_admin)
    login preparer
    post admin_operations_path, params: { operation: "preview", ids: user.id, reason: "Abus" }
    operation = BulkOperation.last
    expect(operation).to be_present
    delete destroy_user_session_path
    login admin
    %w[block crawlers].each do |action|
      post admin_operations_path, params: { operation: action }
      expect(response).to have_http_status(:forbidden)
    end
    delete destroy_user_session_path
    login super_admin
    post admin_operations_path, params: { operation: "execute", record_id: operation.id }
    expect(user.reload).to be_suspended
    post admin_operations_path, params: { operation: "block", email: "invalid" }
    expect(response).to have_http_status(:unprocessable_content)
    post admin_operations_path, params: { operation: "block", email: admin.email }
    expect(response).to have_http_status(:unprocessable_content)
    post admin_operations_path, params: { operation: "block", email: "abuse@example.test", expires_at: 1.day.from_now, reason: "Abus documenté" }
    expect(LoginBlock.blocked?("abuse@example.test")).to be(true)
    post admin_operations_path, params: { operation: "crawlers", search_enabled: "0", training_enabled: "1", reason: "Recette" }
    expect(response).to have_http_status(:unprocessable_content)
    get "/robots.txt"
    expect(response.body).to include("User-agent: *\nAllow: /", "User-agent: GPTBot\nAllow: /\nDisallow: /compte")
    post admin_operations_path, params: { operation: "invalid" }
    expect(response).to have_http_status(:unprocessable_content)
    get admin_operations_path(resource: "user", q: user.id)
    expect(response).to redirect_to(admin_root_path(tab: "activity"))
    get admin_operations_path(resource: "user", format: "csv")
    expect(response).to redirect_to(admin_root_path(tab: "activity"))
    get admin_operations_path(resource: "missing")
    expect(response).to redirect_to(admin_root_path(tab: "activity"))
  end
  it "réserve la révélation au super-admin et respecte les permissions du Studio" do
    grant(admin, "users.read")
    grant(admin, "studio.preview")
    login admin
    post user_admin_operation_path(user), params: { reason: "Tentative" }
    expect(response).to have_http_status(:forbidden)
    get admin_operations_path(resource: "point_entry")
    expect(response).to have_http_status(:forbidden)
    source = Studio.change!(actor: super_admin, name: "Copie privée", settings: {})
    post builder_save_admin_site_path(source), params: { document: {}.to_json, digest: source.digest }
    expect(response).to have_http_status(:forbidden)
    grant(admin, "content.manage")
    post builder_save_admin_site_path(source), params: { document: {}.to_json, digest: source.digest }
    expect(response).to have_http_status(:forbidden)
    delete destroy_user_session_path
    login super_admin
    version = save_studio_version(source, { "site" => { "pages" => { "home" => SiteDesign.home_page } }, "tokens" => { "motion" => "subtle" } })
    expect(version.tokens["motion"]).to eq("subtle")
    delete destroy_user_session_path
    login admin
    post publish_admin_site_path(version), params: { digest: version.digest, live_id: "" }
    expect(response).to have_http_status(:forbidden)
    delete destroy_user_session_path
    login super_admin
    post builder_save_admin_site_path(version), params: { document: "not JSON", digest: version.digest }
    expect(response).to have_http_status(:unprocessable_content)
    get preview_admin_studio_path(version, width: 999)
    expect(response.body).to include("iframe", "1440")
    expect(response.headers["Content-Security-Policy"]).to include("frame-ancestors 'self'")
  end
end
