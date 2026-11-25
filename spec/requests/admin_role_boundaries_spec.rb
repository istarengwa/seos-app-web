require "rails_helper"

RSpec.describe "Accès inclus dans le rôle admin", type: :request do
  it "ouvre le panneau et la modération des annonces sans permission individuelle" do
    admin = create(:user, :admin)
    listing = create(:listing)
    login admin
    get admin_root_path
    expect(response.body).to include("Gérer les annonces")
    expect(response.body).not_to include("Gestion du site", "Propositions éditoriales")
    get admin_workbench_index_path(kind: "annonces")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(listing.title)
    patch admin_workbench_path(listing.id, kind: "annonces"), params: { status: "paused", reason: "Abus examiné par un admin" }
    expect(response).to have_http_status(:see_other)
    expect(listing.reload.moderation_hold).to be(true)
  end

  it "refuse les outils du site même avec toutes les anciennes permissions éditoriales" do
    admin = create(:user, :admin)
    User::SITE_SUPER_ADMIN_PERMISSIONS.each { |permission| create(:admin_permission_grant, user: admin, permission: permission) }
    login admin
    get admin_root_path
    expect(response.body).not_to include("Gestion du site", "Propositions éditoriales", "Kit UI/UX")
    source = Studio.change!(actor: create(:user, :super_admin), name: "Accès", settings: {})
    paths = [ admin_site_index_path, builder_admin_site_path(source), preview_admin_studio_path(source), review_admin_site_path(source) ] + %w[categories contenus].map { |kind| admin_workbench_index_path(kind: kind) }
    paths.each do |path|
      get path
      expect(response).to have_http_status(:forbidden), path
    end
    [ builder_save_admin_site_path(source), builder_preview_admin_site_path(source), publish_admin_site_path(source) ].each do |path|
      expect { post path, params: { document: {}.to_json, digest: source.digest } }.not_to change(StudioVersion, :count)
      expect(response).to have_http_status(:forbidden), path
    end
    category = create(:category)
    get admin_workbench_path(category.id, kind: "categories")
    expect(response).to have_http_status(:forbidden)
    patch admin_workbench_path(category.id, kind: "categories"), params: { record: { name: "Interdit" }, reason: "Tentative" }
    expect(response).to have_http_status(:forbidden)
    expect(category.reload.name).not_to eq("Interdit")
    admin.update!(status: "suspended")
    expect(admin.permission?("listings.moderate")).to be(false)
  end

  it "conserve la gestion du site pour le super admin" do
    super_admin = create(:user, :super_admin)
    login super_admin
    get admin_root_path
    expect(response.body).to include("Éditeur visuel")
    source = Studio.change!(actor: super_admin, name: "Site", settings: {})
    get admin_site_index_path
    expect(response).to redirect_to(builder_admin_site_path(source, page: "home"))
    [ builder_admin_site_path(source), admin_workbench_index_path(kind: "categories") ].each do |path|
      get path
      expect(response).to have_http_status(:ok), path
    end
  end
end
