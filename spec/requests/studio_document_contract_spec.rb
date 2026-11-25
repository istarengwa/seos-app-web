require "rails_helper"

RSpec.describe "Documents et composants du Studio V2", type: :request do
  let(:admin) { create(:user, :super_admin) }
  let(:source) { Studio.change!(actor: admin, name: "Source", settings: {}) }

  before { login admin }

  it "refuse les documents incohérents sans créer de version ni d’audit" do
    block = { "id" => "intro", "template" => "text", "values" => { "body" => "Bienvenue" } }
    page = { "title" => "Accueil", "blocks" => [ block ] }
    invalid_sites = [
      { "inconnu" => true },
      { "pages" => { "don" => page }, "deleted_pages" => [ "don" ] },
      { "header" => { "login_label" => "" } },
      { "pages" => 51.times.to_h { |i| [ "page-#{i}", page ] } },
      { "pages" => { "home" => page.merge("blocks" => Array.new(41) { |i| block.merge("id" => "bloc-#{i}") }) } }
    ]
    invalid_blocks = [
      nil,
      block.merge("template" => "inconnu"),
      block.merge("values" => { "inconnu" => "Texte" }),
      block.merge("elements" => { "inconnu" => { "size" => "small" } }),
      block.merge("children" => [ "élément invalide" ]),
      block.merge("children" => [ { "id" => "titre", "template" => "heading", "values" => {}, "style" => { "align" => "expression(evil)" } } ]),
      block.merge("children" => [ { "id" => "bouton", "template" => "button", "values" => { "url" => "javascript:alert(1)" } } ]),
      block.merge("children" => [ { "id" => "espace", "template" => "spacer", "values" => { "height" => "1201" } } ]),
      { "id" => "hero", "template" => "home-0", "values" => { "slides" => nil } },
      { "id" => "video", "template" => "home-5", "values" => { "video-url" => "https://example.test/script.js" } }
    ]
    invalid_sites += invalid_blocks.map { |invalid| { "pages" => { "home" => page.merge("blocks" => [ invalid ]) } } }
    original = source.settings.deep_dup
    invalid_sites.each do |site|
      expect do
        post builder_save_admin_site_path(source), params: { document: { "site" => site }.to_json, digest: source.digest }, as: :json
      end.not_to change { [ StudioVersion.count, AuditLog.count ] }
      expect(response).to have_http_status(:unprocessable_content), site.inspect
    end
    expect(source.reload.settings).to eq(original)
  end

  it "publie des éléments indépendants avec leurs largeurs, alignements et espacements mobiles" do
    children = [
      { "id" => "titre", "template" => "heading", "values" => { "text" => "Nos rencontres" }, "style" => { "width" => "half", "align" => "left" } },
      { "id" => "texte", "template" => "paragraph", "values" => { "text" => "Une communauté ouverte." }, "style" => { "width" => "third", "align" => "center" } },
      { "id" => "image", "template" => "image", "values" => { "image" => "seos-logo.png", "alt" => "Notre collectif" }, "style" => { "align" => "right" } },
      { "id" => "bouton", "template" => "button", "values" => { "label" => "Nous contacter", "url" => "/contact" } },
      { "id" => "espace", "template" => "spacer", "values" => { "height" => "120", "mobile_height" => "32" } }
    ]
    version = save_studio_version(source, { "site" => { "pages" => { "home" => { "title" => "Accueil", "blocks" => [ { "id" => "libre", "template" => "blank-section", "values" => {}, "children" => children } ] } } } })
    Studio.publish_from_review!(version: version, actor: admin, digest: version.digest, live_id: "")
    get root_path
    expect(response).to have_http_status(:ok)
    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css("#site-element-titre h2").text).to eq("Nos rencontres")
    expect(doc.at_css("#site-element-image img")["alt"]).to eq("Notre collectif")
    expect(doc.at_css("#site-element-bouton a")["href"]).to eq("/contact")
    expect(doc.css("style").text).to include("grid-column:span 6", "grid-column:span 4", "justify-self:start", "justify-self:center", "justify-self:end", "min-height:120px", "min-height:32px")
  end

  it "recalcule les missions et documents légaux dans les emplacements du canevas" do
    pages = %w[legal voyage-solidaire].to_h do |slug|
      page = SiteDesign.default_page(slug)
      slot = slug == "legal" ? "legal-tabs-slot" : "travel-missions-slot"
      [ slug, page.merge("canvas" => { "version" => 1, "html" => "<section><h1>Présentation V2</h1><div class='#{slot}'>Contenu périmé</div></section>", "css" => "" }) ]
    end
    version = save_studio_version(source, { "site" => { "pages" => pages } }, page: "legal")
    Studio.publish_from_review!(version: version, actor: admin, digest: version.digest, live_id: "")
    get legal_center_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("legal-cgu", "legal-confidentialite")
    expect(response.body).not_to include("Contenu périmé")
    get volunteer_missions_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Filtrer les missions")
    expect(response.body).not_to include("Contenu périmé")
  end

  it "présente les changements de menu, de footer et de thème avant publication" do
    live = save_studio_version(source, { "site" => { "pages" => { "home" => SiteDesign.home_page, "equipe" => { "title" => "Notre équipe", "blocks" => [] } } } })
    %w[validate publish].each { |action| Studio.transition!(version: live, actor: admin, action: action, reason: "Référence de comparaison") }
    document = live.settings.deep_dup
    document["site"]["pages"].delete("equipe")
    document["site"]["deleted_pages"] = [ "equipe" ]
    document["site"]["header"] = { "login_label" => "Entrer" }
    document["site"]["footer"] = { "title" => "Entraidons-nous" }
    document["tokens"] = { "card-radius" => "24px", "wave-height" => "100px", "wave-shape" => "curve", "font-body" => "DM Sans, sans-serif", "font-heading" => "Playfair Display, serif" }
    draft = save_studio_version(live, document)
    get review_admin_site_path(draft)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Page supprimée : Notre équipe", "Haut du site : logo et menu", "Bas du site : informations et liens", "Couleurs et apparence de l’ensemble du site")
    expect(draft.css).to include("border-radius:var(--card-radius)", "height:var(--wave-height)", "clip-path:none", "font-family:var(--font-body)", "font-family:var(--font-heading)")
    expect(live.reload.settings).not_to eq(draft.settings)
  end

  it "bloque une publication devenue illisible sans valider ni auditer la version" do
    draft = save_studio_version(source, { "tokens" => { "ink" => "#FFFFFF", "cream" => "#FFFFFF" } })
    expect do
      post publish_admin_site_path(draft), params: { digest: draft.digest, live_id: "" }
    end.not_to change(AuditLog, :count)
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("difficiles à lire")
    expect(draft.reload.status).to eq("draft")
    expect(StudioVersion.current).to be_nil
  end
end
