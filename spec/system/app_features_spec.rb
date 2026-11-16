require "rails_helper"

RSpec.describe "Gestion des fonctionnalités", type: :system do
  let(:admin) { create(:user, :super_admin) }

  before do
    visit new_user_session_path
    fill_in "E-mail", with: admin.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
  end

  it "désactive puis réactive les associations sans effacer le dossier" do
    organization = organization_space
    [ 1440, 375 ].each do |width|
      resize_viewport(width)
      visit admin_features_path
      expect(page).to have_css("#feature-associations")
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
      page.save_screenshot(Rails.root.join("tmp/screenshots/features-#{width}.png"))
    end
    resize_viewport(1440)
    within("#feature-associations") do
      select "Désactivé", from: "État de Associations"
      fill_in "Motif du changement", with: "Lancement des associations plus tard"
      click_button "Vérifier les conséquences"
    end
    expect(page).to have_content("Missions dépendantes")
    expect(AppFeatures.enabled?("associations")).to be(true)
    [ 1440, 375 ].each do |width|
      resize_viewport(width)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
      confirmation = find(".feature-confirmation")
      page.execute_script("arguments[0].scrollIntoView({ block: 'start', behavior: 'instant' })", confirmation)
      confirmation.native.save_screenshot(Rails.root.join("tmp/screenshots/feature-confirmation-#{width}.png").to_s)
    end
    resize_viewport(1440)
    click_button "Confirmer ce changement"
    expect(page).to have_content("Fonctionnalité mise à jour")
    expect(AppFeatures.enabled?("associations")).to be(false)
    expect(organization.reload).to be_verified
    visit community_path
    expect(page).not_to have_content("Les associations ont leur place ici")
    visit admin_network_path(organization.id, section: "organizations")
    expect(page).to have_content("Consultation des données conservées")
    expect(page).to have_field("Décision", disabled: true)
    page.save_screenshot(Rails.root.join("tmp/screenshots/features-associations-readonly.png"))
    visit admin_features_path
    within("#feature-associations") do
      select "Actif", from: "État de Associations"
      fill_in "Motif du changement", with: "Ouverture au public"
      click_button "Vérifier les conséquences"
    end
    click_button "Confirmer ce changement"
    expect(page).to have_content("Fonctionnalité mise à jour")
    visit community_path
    expect(page).to have_content("Les associations ont leur place ici")
    expect(organization.reload).to be_verified
  end

  it "lie un bloc libre à un module et conserve le bloc masqué dans le Studio" do
    version = Studio.change!(actor: admin, name: "Bloc optionnel", settings: { "site" => { "pages" => { "home" => { "title" => "Accueil", "blocks" => [ { "id" => "intro", "template" => "text", "values" => { "title" => "Notre contenu optionnel", "body" => "Ce contenu suit les chaînes." } } ] } } } })
    visit builder_admin_site_path(version)
    within_frame(find(".gjs-frame")) { find("h2", text: "Notre contenu optionnel").click }
    click_button "Avancé", exact: true
    select "Chaînes d’entraide", from: "Afficher avec une fonctionnalité"
    click_button "Enregistrer", exact: true
    expect(page).to have_content("Modifications enregistrées")
    draft = StudioVersion.last
    expect(draft.site.dig("pages", "home", "canvas", "html")).to include('data-app-feature="chains"')
    %w[validate publish].each { |action| Studio.transition!(version: draft, actor: admin, action: action, reason: "Publication du bloc") }
    AppFeatures.change!(actor: admin, key: "chains", enabled: false, reason: "Plus tard", expected: AppFeatures.digest)
    visit root_path
    expect(page).not_to have_content("Notre contenu optionnel")
    expect(page).to have_content("Ce contenu suit les chaînes.")
    visit builder_admin_site_path(draft)
    within_frame(find(".gjs-frame")) do
      expect(page).to have_css('[data-app-feature="chains"][data-app-feature-disabled="true"]', text: "Notre contenu optionnel")
    end
    page.save_screenshot(Rails.root.join("tmp/screenshots/features-studio-disabled.png"))
  end
end
