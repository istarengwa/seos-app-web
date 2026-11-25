require "rails_helper"
RSpec.describe "Composition du site", type: :request do
  let(:admin) { create(:user, :super_admin) }
  def publish(version)
    %w[validate publish].each { |action| Studio.transition!(version: version, actor: admin, action: action, reason: "Recette du site") }
  end
  def draft
    Studio.change!(actor: admin, settings: {}, name: "Site de recette")
  end
  it "réserve le constructeur et son aperçu au super admin" do
    login create(:user)
    get admin_site_index_path
    expect(response).to have_http_status(:forbidden)
    get builder_admin_site_path(draft)
    expect(response).to have_http_status(:forbidden)
    get preview_admin_studio_path(draft, canvas: "1")
    expect(response).to have_http_status(:forbidden)
  end

  it "ouvre la V2 et propose les pages et compositions actives" do
    login admin
    get admin_site_index_path
    expect(response).to have_http_status(:see_other)
    follow_redirect!
    expect(response.body).to include("Studio V2", "Édition directe")
    config = studio_builder_configuration
    expect(config.fetch("pages").keys).to match_array(StudioVersion.last.available_pages)
    expect(config.fetch("templates").keys).to match_array(SiteDesign.editable_templates.keys)
    expect(config.fetch("templates").keys & SiteDesign::RETIRED_TEMPLATES).to be_empty
    expect(config.fetch("initialHtml")).to include('data-studio-chrome="header"', 'data-studio-chrome="footer"')
    expect(response.headers["Cache-Control"]).to include("no-store")
  end

  it "enregistre une composition modifiée sans muter la source" do
    login admin
    original = Studio.change!(actor: admin, name: "Sections existantes", settings: { "site" => { "pages" => { "home" => SiteDesign.home_page } } })
    document = original.settings.deep_dup
    blocks = document.dig("site", "pages", "home", "blocks")
    first = blocks.first.deep_dup
    first["id"] = "copie-hero"
    first["hidden"] = true
    first["values"]["text-1"] = "Une section conservée mais masquée"
    blocks << first
    blocks.rotate!
    blocks.delete_at(1)
    saved = save_studio_version(original, document)
    expect(saved.site).to eq(document.fetch("site"))
    expect(saved.site.dig("pages", "home", "blocks").find { |block| block["id"] == "copie-hero" }).to eq(first)
    expect(original.reload.site.dig("pages", "home")).to eq(SiteDesign.home_page)
    get builder_admin_site_path(saved)
    expect(response).to have_http_status(:ok)
  end

  it "publie une page et le pied de page puis enregistre un retour à la présentation par défaut" do
    login admin
    original = draft
    settings = { "site" => {
      "pages" => { "notre-association" => { "title" => "Notre association", "blocks" => [ { "id" => "intro", "template" => "text", "values" => { "title" => "Notre association", "body" => "Entraidons-nous." } } ] } },
      "footer" => { "title" => "Ensemble ici", "description" => "À Paris", "logo" => "seos-logo.png", "alt" => "Notre logo", "links" => [ { "label" => "Association", "url" => "/pages/notre-association" } ] }
    } }
    version = save_studio_version(original, settings, page: "notre-association")
    get preview_admin_studio_path(version, page: "notre-association", canvas: "1")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Notre association", "Ensemble ici")
    get site_page_path("notre-association")
    expect(response).to have_http_status(:not_found)
    publish(version)
    get site_page_path("notre-association")
    expect(response.body).to include("Ensemble ici", "Notre association")
    get sitemap_path
    expect(response.body).to include(site_page_url("notre-association"))
    settings["site"].delete("footer")
    reset = save_studio_version(version, settings, page: "notre-association")
    expect(reset.chrome("footer")["title"]).to eq(SiteDesign::CHROME["footer"]["title"])
    expect(reset.site["pages"]).to eq(version.site["pages"])
    expect(version.reload.status).to eq("published")
  end

  it "publie les sections de maquette avec valeurs échappées et liens réels" do
    values = { "text-0" => '<script>alert("x")</script>' }
    blocks = [ { "id" => "hero", "template" => "home-0", "values" => values } ]
    version = Studio.change!(actor: admin, name: "Maquette", settings: { "site" => { "pages" => { "home" => { "title" => "Accueil", "blocks" => blocks } } } })
    publish(version)
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('&lt;script&gt;', '/compte/annonces/new')
    expect(response.body).not_to include('<script>alert', '/users/sign_up')
  end
  it "refuse les liens exécutables, les templates inconnus et les documents malformés" do
    base = { "id" => "abc", "template" => "text", "values" => { "url" => "javascript:alert(1)" } }
    expect(SiteDesign.valid_block?(base)).to be(false)
    %w[//evil.test /\\evil.test https://user@evil.test http://evil.test].each do |url|
      expect(SiteDesign.safe_url?(url)).to be_falsey
    end
    expect(SiteDesign.valid?({ "pages" => [] })).to be(false)
    expect(SiteDesign.valid_block?(base.merge("template" => "../../secret"))).to be(false)
    expect(SiteDesign.valid_block?(base.merge("values" => { "extra" => "value" }))).to be(false)
    login admin
    source = draft
    bad = { "site" => { "pages" => { "home" => { "title" => "Accueil", "blocks" => [ base.merge("template" => "bad") ] } } } }
    expect { post builder_save_admin_site_path(source), params: { document: bad.to_json, digest: source.digest } }.not_to change(StudioVersion, :count)
    expect(response).to have_http_status(:unprocessable_content)
  end
  it "conserve les images des brouillons privées et révoque l'accès après masquage" do
    asset = StudioAsset.create!(author: admin)
    SafeImage.attach!(asset.image, Rack::Test::UploadedFile.new(Rails.root.join("app/assets/images/seos-logo.png"), "image/png"))
    block = { "id" => "hero", "template" => "home-0", "values" => { "image-0" => "asset:#{asset.id}", "alt-0" => "L’équipe" } }
    settings = { "site" => { "pages" => { "home" => { "title" => "Accueil", "blocks" => [ block ] } } } }
    version = Studio.change!(actor: admin, name: "Image", settings: settings)
    get media_path(asset.image.attachment)
    expect(response).to have_http_status(:not_found)
    publish(version)
    get media_path(asset.image.attachment)
    expect(response).to have_http_status(:ok)
    settings["site"]["pages"]["home"]["blocks"][0]["hidden"] = true
    hidden = Studio.change!(actor: admin, name: "Masquage", settings: settings, source: version)
    publish(hidden)
    get media_path(asset.image.attachment)
    expect(response).to have_http_status(:not_found)
  end
  it "enregistre et retire les tokens sans modifier les pages" do
    login admin
    original = draft
    settings = { "site" => { "pages" => { "home" => SiteDesign.home_page } }, "tokens" => { "wave-speed" => "12s", "wave-shape" => "diagonal", "motion" => "subtle", "section-space" => "72px", "button-radius" => "26px" } }
    version = save_studio_version(original, settings)
    expect(version.css).to include("seos-wave", "12s", "polygon", "prefers-reduced-motion")
    settings["tokens"] = {}
    reset = save_studio_version(version, settings)
    expect(reset.tokens).to eq({})
    expect(reset.site).to eq(version.site)
    expect(version.reload.tokens["wave-speed"]).to eq("12s")
  end

  it "rend toutes les sections sans reprendre les données personnelles de démonstration" do
    blocks = SiteDesign.templates.keys.map.with_index { |key, i| { "id" => "section-#{i}", "template" => key, "values" => {}, "separator" => "wave_single", "placement" => i.even? ? "top" : "bottom" } }
    version = Studio.change!(actor: admin, name: "Toutes les sections", settings: { "site" => { "pages" => { "home" => { "title" => "Accueil", "blocks" => blocks } } } })
    %w[validate publish].each { |action| Studio.transition!(version: version, actor: admin, action: action, reason: "Recette") }
    get root_path
    expect(response).to have_http_status(:ok)
    expect(Nokogiri::HTML(response.body).css("h1").size).to eq(1)
    expect(response.body).to include("Aucune annonce", "témoignages publiés")
    expect(response.body).not_to include("Amina B.", "63 échanges", "40 Points Services en circulation")
  end
  it "édite le modèle de don avec un identifiant stable" do
    content = ContentVersion.create!(author: admin, kind: "page", slug: "don", title: "Donner", summary: "Librement", body: "Aucune contrepartie", version: 1, published_at: Time.current)
    first = SiteDesign.default_page("don")
    expect(first).to eq(SiteDesign.default_page("don"))
    version = Studio.change!(actor: admin, name: "Page", settings: {})
    login admin
    first["blocks"].first["values"].merge!("text-1" => "Un nouveau titre", "text-3" => content.body)
    first["blocks"].first.merge!("separator" => "wave_double", "placement" => "top")
    version = save_studio_version(version, { "site" => { "pages" => { "don" => first } } }, page: "don")
    expect(version.site.dig("pages", "don", "blocks", 0, "values", "text-1")).to eq("Un nouveau titre")
    get preview_admin_studio_path(version, page: "don", canvas: "1")
    expect(response.body).to include("Un nouveau titre", "wave_double")
  end
  it "rejette les opérations et destinations non prévues sans écrire de brouillon" do
    version = Studio.change!(actor: admin, name: "Page", settings: {})
    login admin
    invalid = [ { "untrusted" => {} }, { "site" => { "pages" => { "../" => {} } } }, { "site" => { "header" => { "logo" => "https://evil.test/image.png", "alt" => "Logo" } } } ]
    invalid.each do |document|
      expect { post builder_save_admin_site_path(version), params: { document: document.to_json, digest: version.digest } }.not_to change(StudioVersion, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
    expect { Studio.change!(actor: create(:user, :admin), name: "Effacement", settings: { "site" => {} }, source: version) }.to raise_error(Pundit::NotAuthorizedError)
    expect(SiteDesign.safe_url?("https://example.org/")).to be(true)
    expect(SiteDesign.safe_url?("https://[malformed")).to be(false)
    expect(SiteDesign.safe_url?("#presentation")).to be(true)
    expect(SiteDesign.valid?({ "header" => { "logo" => "seos-logo.png" } })).to be(false)
    expect(SiteDesign.valid?({ "header" => { "bad" => "value" } })).to be(false)
    expect(SiteDesign.valid?({ "pages" => { "bad slug" => {} } })).to be(false)
  end
end

RSpec.describe "Sections alimentées par les données publiques", type: :request do
  it "utilise les annonces éligibles et les témoignages consentis" do
    listing = create(:listing, title: "Atelier partagé", address_line: "14 rue Secrète")
    listing.photos.attach(io: File.open(Rails.root.join("app/assets/images/seos-logo.png")), filename: "photo.png", content_type: "image/png")
    hidden = create(:listing, title: "Annonce brouillon invisible", status: "draft")
    testimonial = Testimonial.create!(user: listing.user, kind: "written", status: "published", quote: "Une expérience partagée", display_name_snapshot: "Camille", public_location_snapshot: "Lyon", consent_version: Testimonial::CONSENT_VERSION, consented_at: Time.current)
    admin = create(:user, :super_admin)
    blocks = %w[home-2 home-3 home-6].map { |template| { "id" => template, "template" => template, "values" => {} } }
    version = Studio.change!(actor: admin, name: "Communauté", settings: { "site" => { "pages" => { "home" => { "title" => "Notre communauté", "blocks" => blocks } } } })
    %w[validate publish].each { |action| Studio.transition!(version: version, actor: admin, action: action, reason: "Recette") }
    get root_path
    expect(response.body).to include(listing.title, listing.category.name, testimonial.quote)
    expect(response.body).not_to include(hidden.title, listing.user.email, "14 rue Secrète")
    testimonial.update!(removed_at: Time.current)
    listing.user.update!(status: "suspended")
    get root_path
    expect(response.body).not_to include(listing.title, testimonial.quote)
  end
end
