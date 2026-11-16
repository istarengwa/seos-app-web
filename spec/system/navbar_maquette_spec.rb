require "rails_helper"

RSpec.describe "Navigation publique conforme à la maquette", type: :system do
  it "place la connexion blanche avant la publication, sans troisième bouton" do
    FeatureFlag.find_or_create_by!(key: "voyage_enabled").update!(enabled: true)
    visit listings_path
    [ 1440, 1233 ].each do |width|
      resize_viewport(width)
      within(".topbar") do
        expect(page).to have_css('.nav-links [aria-current="page"]', text: "Annonces")
        expect(page).to have_link("Voyage solidaire")
        expect(page).not_to have_link("Rejoindre SEOS")
        expect(all('.nav-actions > a').map(&:text)).to eq([ "Connexion", "+ Publier une annonce" ])
        expect(find('.login-link').native.css_value("background-color")).to eq("rgba(255, 255, 255, 1)")
        expect(find('.login-link').native.rect.x).to be < find('.nav-publish').native.rect.x
      end
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21aa, :wcag22aa)
      page.save_screenshot(Rails.root.join("tmp/screenshots/navbar-public-#{width}.png"))
    end
    resize_viewport(375)
    find('.mobile-navigation > summary').send_keys(:enter)
    within('.mobile-navigation') do
      expect(page).to have_link("Connexion", href: new_user_session_path)
      expect(page).to have_link("Créer un compte", href: new_user_registration_path)
      expect(page).to have_link("+ Publier une annonce", href: new_account_listing_path)
    end
    expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
    resize_viewport(1440)
    within('.nav-actions') { click_link "Connexion", visible: true }
    expect(page).to have_current_path(new_user_session_path)
  end

  it "superpose une navigation transparente aux en-têtes publics, même pour un super-admin" do
    admin = create(:user, :super_admin)
    version = Studio.change!(actor: admin, name: "En-têtes publics", settings: {
      "tokens" => { "deep" => "#004961" }, "site" => { "pages" => { "home" => SiteDesign.home_page } }
    })
    Studio.publish_from_review!(version: version, actor: admin, digest: version.digest, live_id: "")
    visit new_user_session_path
    fill_in "E-mail", with: admin.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    [ 375, 1440 ].each do |width|
      resize_viewport(width)
      [ root_path, listings_path, community_path, volunteer_missions_path, explanation_path("don"), explanation_path("echange"), explanation_path("points") ].each do |path|
        visit path
        hero = find("main :is(.hero,.public-hero,.info-hero,.travel-hero)", match: :first)
        geometry = page.evaluate_script(<<~JS)
          (() => {
            const nav = document.querySelector('.topbar');
            const style = getComputedStyle(nav);
            return { navBottom: nav.getBoundingClientRect().bottom, background: style.backgroundColor, image: style.backgroundImage, blur: style.backdropFilter };
          })()
        JS
        # The header starts at the viewport edge, behind the navigation.
        expect(hero.native.rect.y).to be_within(1).of(0)
        expect(geometry).to include("background" => "rgba(0, 0, 0, 0)", "image" => "none", "blur" => "none")
        expect(page).not_to have_button("Modifier cette page")
        expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
        expect(hero.find("h1").native.rect.y).to be >= geometry.fetch("navBottom")
        page.save_screenshot(Rails.root.join("tmp/screenshots/overlay-#{path.parameterize.presence || 'home'}-#{width}.png"))
      end
    end
    visit contact_path
    expect(find(".topbar").native.css_value("background-color")).to eq("rgba(0, 0, 0, 0)")
    expect(find(".topbar .nav-links a", match: :first).native.css_value("color")).to eq("rgba(0, 73, 97, 1)")
  end

  it "garde la superposition après l’enregistrement d’un canevas V2" do
    admin = create(:user, :super_admin)
    source = Studio.change!(actor: admin, name: "Source", settings: { "site" => { "pages" => { "home" => SiteDesign.home_page } } })
    visit new_user_session_path
    fill_in "E-mail", with: admin.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    visit builder_admin_site_path(source)
    config = page.evaluate_script("JSON.parse(document.querySelector('[data-studio-config]').textContent)")
    canvas = Nokogiri::HTML5.fragment(config.fetch("initialHtml"))
    canvas.css("[data-studio-chrome]").remove
    canvas.css("[data-studio-page]").each { |node| node.replace(node.children) }
    settings = source.settings.deep_dup
    settings["site"]["pages"]["home"]["canvas"] = { "version" => 1, "html" => canvas.to_html, "css" => config.fetch("initialCss") }
    version = Studio.change!(actor: admin, source: source, name: "Canevas enregistré", settings: settings)
    Studio.publish_from_review!(version: version, actor: admin, digest: version.digest, live_id: "")
    [ 375, 1440 ].each do |width|
      resize_viewport(width)
      visit root_path
      expect(find("main .hero").native.rect.y).to be_within(1).of(0)
      expect(find(".topbar").native.css_value("background-color")).to eq("rgba(0, 0, 0, 0)")
      expect(page).not_to have_button("Modifier cette page")
      page.save_screenshot(Rails.root.join("tmp/screenshots/overlay-canvas-#{width}.png"))
    end
  end
end
