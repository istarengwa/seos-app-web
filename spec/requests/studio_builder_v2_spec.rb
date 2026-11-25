require "rails_helper"

RSpec.describe "Studio V2", type: :request do
  it "réserve le constructeur visuel au super-admin et enregistre un brouillon sûr" do
    admin = create(:user, :super_admin)
    source = Studio.change!(
      actor: admin,
      name: "Source Studio V2",
      settings: { "site" => { "pages" => { "home" => SiteDesign.home_page } } }
    )

    login create(:user)
    get builder_admin_site_path(source)
    expect(response).to have_http_status(:forbidden)

    delete destroy_user_session_path
    login admin
    get builder_admin_site_path(source)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Studio V2", "Édition directe", "Compositions", "data-studio-styles")

    document = source.settings.deep_dup
    document["tokens"] = source.tokens.merge("wave-angle" => "7deg", "wave-speed" => "11s", "wave-amplitude" => "16px", "wave-roundness" => "73%")
    document.dig("site", "pages", "home")["canvas"] = {
      "version" => 1,
      "html" => '<main><h1 style="font-weight:700">Un titre construit librement</h1><div class="ad-grid"><article>Fausse annonce écrite dans le Studio</article></div><script>alert(1)</script></main>',
      "css" => "h1{font-family:serif}"
    }
    post builder_save_admin_site_path(source), params: { document: document.to_json, digest: source.digest, page: "home" }, as: :json

    expect(response).to have_http_status(:ok)
    result = response.parsed_body
    draft = StudioVersion.find(result.fetch("url").match(%r{/admin/site/(\d+)/builder})[1])
    expect(draft.tokens).to include("wave-angle" => "7deg", "wave-speed" => "11s", "wave-amplitude" => "16px", "wave-roundness" => "73%")
    expect(draft.site.dig("pages", "home", "canvas", "html")).to include("Un titre construit librement", "font-weight:700")
    expect(draft.site.dig("pages", "home", "canvas", "html")).not_to include("script", "alert", "Fausse annonce")
    expect(draft.site.dig("pages", "home", "canvas", "css")).to eq("h1{font-family:serif}")
    expect(draft.css).to include(".site-wave-layers", "rotate:var(--wave-angle)", "animation:seos-wave", "border-radius:var(--wave-roundness)")
    expect(result.fetch("review")).to eq(review_admin_site_path(draft, page: "home"))

    post builder_preview_admin_site_path(source), params: { document: draft.settings.to_json, page: "home", revision: "canvas" }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Un titre construit librement", "h1{font-family:serif}")
    expect(response.body).not_to include("alert(1)", "Fausse annonce écrite dans le Studio")
  end

  it "rejette les angles de vague hors des limites autorisées" do
    admin = create(:user, :super_admin)
    source = Studio.change!(actor: admin, name: "Source", settings: {})
    login admin
    document = source.settings.deep_dup
    document["tokens"] = { "wave-angle" => "999deg" }

    post builder_save_admin_site_path(source), params: { document: document.to_json, digest: source.digest, page: "home" }, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.fetch("error")).to include("wave-angle")
  end
end

RSpec.describe "Migration du Studio vers la V2", type: :request do
  it "ouvre la V2 depuis le Studio et les anciens liens, sans proposer la V1" do
    admin = create(:user, :super_admin)
    source = Studio.change!(actor: admin, name: "Copie existante", settings: {})
    login admin
    get admin_site_index_path(page: "legal")
    expect(response).to redirect_to(builder_admin_site_path(source, page: "legal"))
    get visual_admin_site_path(source, page: "legal")
    expect(response).to redirect_to(builder_admin_site_path(source, page: "legal"))
    follow_redirect!
    expect(response.body).to include("Studio V2")
    expect(response.body).not_to include("Ancien éditeur", 'data-controller="visual-studio"')
    expect(Rails.application.routes.recognize_path("/admin/site/#{source.id}/builder_save", method: :post)).to include(action: "builder_save")
    expect { Rails.application.routes.recognize_path("/admin/site/#{source.id}/visual_save", method: :post) }.to raise_error(ActionController::RoutingError)
  end

  it "conserve la page, la relecture et la publication d’une composition V2" do
    admin = create(:user, :super_admin)
    source = Studio.change!(actor: admin, name: "Copie V2", settings: {})
    login admin
    document = { "site" => { "pages" => { "communaute" => SiteDesign.default_page("communaute").merge(
      "canvas" => { "version" => 1, "html" => "<section><h1>La communauté V2 publiée</h1></section>", "css" => "" }
    ) } } }
    post builder_save_admin_site_path(source), params: { document: document.to_json, digest: source.digest, page: "communaute" }
    expect(response).to have_http_status(:ok)
    draft = StudioVersion.last
    expect(response.parsed_body.fetch("review")).to eq(review_admin_site_path(draft, page: "communaute"))
    get review_admin_site_path(draft, page: "communaute")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(builder_admin_site_path(draft, page: "communaute"))
    get preview_admin_studio_path(draft, page: "communaute", canvas: "1")
    expect(response.body).to include("La communauté V2 publiée")
    post publish_admin_site_path(draft), params: { digest: draft.digest, live_id: "", page: "communaute" }
    expect(response).to redirect_to(admin_site_index_path(page: "communaute"))
    get community_path
    expect(response.body).to include("La communauté V2 publiée")
  end
end
