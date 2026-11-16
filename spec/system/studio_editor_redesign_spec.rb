require "rails_helper"

RSpec.describe "Studio accessible, vagues et documents", type: :system do
  let(:admin) { create(:user, :super_admin) }
  let(:source) do
    Studio.change!(actor: admin, name: "Édition guidée", settings: { "site" => { "pages" => { "home" => {
      "title" => "Accueil", "blocks" => [ { "id" => "intro", "template" => "text", "separator" => "wave_double", "values" => { "title" => "Notre collectif", "body" => "Bienvenue chez nous." } } ]
    } } } })
  end

  before do
    visit new_user_session_path
    fill_in "E-mail", with: admin.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    visit builder_admin_site_path(source)
    expect(page).to have_css(".gjs-frame")
  end

  it "garde les outils clairs et change de page sans fausse alerte après une sélection" do
    within_frame(find(".gjs-frame")) { find("h2", text: "Notre collectif").click }
    expect(page).to have_css(".studio-simple-controls legend", text: "Typographie")
    expect(page).to have_select("Taille du texte", with_options: [ "Petit", "Normal", "Grand" ])
    expect(page).not_to have_content("Font weight")
    within(".studio-v2-sidebar-tabs") { click_button "Structure" }
    layer = find(".gjs-layer-title", match: :first)
    expect(layer.native.css_value("background-color")).not_to eq("rgba(68, 68, 68, 1)")
    expect do
      select "Confiance et informations légales", from: "Page à modifier"
      expect(page).to have_current_path(builder_admin_site_path(source, page: "legal"))
      expect(page).to have_css('[data-studio-panel="legal"]:not([hidden])')
    end.not_to change(StudioVersion, :count)
    within_frame(find(".gjs-frame")) do
      current = find('.legal-sidebar a[aria-current="location"]')
      expect(current.native.css_value("color")).to eq("rgba(0, 121, 157, 1)")
    end
    page.save_screenshot(Rails.root.join("tmp/screenshots/studio-legal-editor.png"))
  end

  it "enregistre les modifications avant de changer de page sans les perdre" do
    within_frame(find(".gjs-frame")) do
      find("h2", text: "Notre collectif").double_click
      find('[contenteditable="true"]').send_keys([ :control, "a" ], "Un titre modifié sans code")
      find("footer").click
    end
    select "Confiance et informations légales", from: "Page à modifier"
    expect(page).to have_css('[data-studio-panel="legal"]:not([hidden])')
    expect(StudioVersion.last.id).not_to eq(source.id)
    expect(StudioVersion.last.site.dig("pages", "home", "canvas", "html")).to include("Un titre modifié sans code")
    expect(source.reload.site.dig("pages", "home", "canvas")).to be_nil
  end

  it "sélectionne une vague existante, la retourne et enregistre les formes SVG" do
    within_frame(find(".gjs-frame")) { find(".site-transition").click }
    expect(page).to have_css('[data-wave-controls]:not([hidden])')
    expect(page).to have_css('[data-studio-selection-name]', text: "Vague de séparation")
    select "Vers le bas", from: "Direction"
    page.execute_script("const color = document.querySelector('[data-wave-color]'); color.value = '#cdae4f'; color.dispatchEvent(new Event('input', {bubbles:true}))")
    click_button "Miroir horizontal"
    expect(find('[data-studio-flip="x"]')["aria-pressed"]).to eq("true")
    within_frame(find(".gjs-frame")) do
      expect(page).to have_css('[data-wave-direction="down"] g[transform*="-1"]', visible: :all)
    end
    select "Vers la gauche", from: "Direction"
    page.execute_script("const input = document.querySelector('[data-wave-control=height]'); input.value = '140'; input.dispatchEvent(new Event('input', {bubbles:true}))")
    click_button "Enregistrer", exact: true
    expect(page).to have_content("Modifications enregistrées")
    draft = StudioVersion.last
    html = draft.site.dig("pages", "home", "canvas", "html")
    expect(html).to include('data-wave-direction="left"', "<g", "<rect", "matrix(0 1 -1 0")
    expect(draft.site.dig("pages", "home", "canvas", "css")).to include("scale:-1 1")
    within_frame(find(".gjs-frame")) do
      graphic = find('.site-transition svg', match: :first)
      expect(page.evaluate_script("arguments[0].querySelector('[data-wave-rotation]').namespaceURI", graphic.native)).to eq("http://www.w3.org/2000/svg")
      expect(page.evaluate_script("getComputedStyle(arguments[0].querySelector('path:last-child')).fill", graphic.native)).to eq("rgb(205, 174, 79)")
    end
    page.save_screenshot(Rails.root.join("tmp/screenshots/studio-wave-controls.png"))
  end

  it "conserve les retouches faites pendant un enregistrement de document" do
    select "Confiance et informations légales", from: "Page à modifier"
    fill_in "Titre du document", with: "Premier titre enregistré"
    page.execute_script(<<~JS)
      window.originalFetch = window.fetch;
      window.fetch = (...args) => window.originalFetch(...args).then(response => new Promise(resolve => setTimeout(() => resolve(response), 1200)));
    JS
    click_button "Enregistrer", exact: true
    expect(page).to have_button("Enregistrement…", disabled: true)
    fill_in "Titre du document", with: "Retouche pendant la sauvegarde"
    expect(page).to have_button("Enregistrer", disabled: false, exact: true)
    expect(page).to have_content("Modifications non enregistrées")
    slug = find("[data-legal-document]").value
    expect(StudioVersion.last.legal_documents.fetch(slug).fetch("title")).to eq("Premier titre enregistré")
    expect(page).to have_field("Titre du document", with: "Retouche pendant la sauvegarde")
    page.execute_script("window.fetch = window.originalFetch")
    click_button "Enregistrer", exact: true
    expect(page).to have_content("Modifications enregistrées")
    expect(StudioVersion.last.legal_documents.fetch(slug).fetch("title")).to eq("Retouche pendant la sauvegarde")
  end

  it "rédige un document légal, le vérifie en plein écran à plusieurs largeurs et le publie" do
    select "Confiance et informations légales", from: "Page à modifier"
    expect(page).to have_css('[data-studio-panel="legal"]:not([hidden])')
    select "Conditions générales d’utilisation", from: "Document à rédiger"
    fill_in "Titre du document", with: "Les règles de notre communauté"
    fill_in "Résumé", with: "Un cadre clair pour nous entraider."
    find("[data-legal-body]").click
    find("[data-legal-body]").send_keys([ :control, :home ], [ :control, :shift, :end ], :backspace, "Chaque membre respecte les personnes rencontrées.")
    expect(ContentVersion.where(kind: "legal")).not_to exist
    click_button "Vérifier et publier"
    expect(page).to have_css(".studio-review")
    expect(page).not_to have_css(".admin-sidebar")
    within_frame(find("iframe")) { expect(page).to have_content("Les règles de notre communauté") }
    click_button "Téléphone"
    expect(find("iframe").native.rect.width).to eq(390)
    page.execute_script("const slider = document.querySelector('[data-studio-review-target=slider]'); slider.value = '555'; slider.dispatchEvent(new Event('input', {bubbles:true}))")
    expect(find("iframe").native.rect.width).to eq(555)
    click_button "Taille réelle"
    expect(find("iframe").native.rect.width).to be >= 1400
    resize_viewport(2560)
    expect(page).to have_css('[data-studio-review-target="label"]', text: "2560 px")
    expect(find("iframe").native.rect.width).to eq(2560)
    resize_viewport(1440)
    expect(page).to have_css('[data-studio-review-target="label"]', text: "1440 px")
    page.save_screenshot(Rails.root.join("tmp/screenshots/studio-review-fullscreen.png"))
    click_button "Enregistrer et publier"
    expect(page).to have_css("[data-studio-builder]")
    document = ContentVersion.current("legal", "cgu")
    expect(document.title).to eq("Les règles de notre communauté")
    expect(document.body).to eq("Chaque membre respecte les personnes rencontrées.")
    visit legal_center_path
    expect(page).to have_content("Chaque membre respecte les personnes rencontrées.")
  end
end
