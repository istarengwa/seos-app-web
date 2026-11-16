require "rails_helper"

RSpec.describe "Vue d’ensemble avec onglets", type: :system do
  def sign_in_admin(user)
    visit new_user_session_path
    fill_in "E-mail", with: user.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
  end

  it "sépare les rubriques sur mobile et ordinateur avec des onglets accessibles" do
    sign_in_admin(create(:user, :super_admin))
    [ 1440, 375 ].each do |width|
      resize_viewport(width)
      visit admin_root_path
      heading = find(".admin-console-heading").native.rect
      tabs = find(".admin-overview-tabs").native.rect
      expect(heading.width).to be > find(".admin-workspace").native.rect.width * 0.85
      expect(tabs.y).to be >= heading.y + heading.height
      expect(page).to have_css('[role="tabpanel"]:not([hidden])', count: 1)
      expect(page).to have_css(".activity-plot")
      all(".admin-activity-summary .card").each do |card|
        label = card.find("span").native.rect
        expect(card.find("a").native.rect.y).to be >= label.y + label.height + 4
        expect(card).not_to have_content("Situation actuelle")
      end
      page.execute_script("arguments[0].scrollIntoView({block: 'center'})", find(".admin-activity-summary").native)
      page.save_screenshot(Rails.root.join("tmp/screenshots/admin-summary-#{width}.png"))
      expect(page).not_to have_button("Bloquer cet e-mail")
      click_link "Outils de gestion"
      expect(page).to have_link("Gérer les annonces")
      expect(page).not_to have_css(".activity-plot")
      click_link "Accès des membres"
      expect(page).to have_field("Adresse e-mail à bloquer", placeholder: "Ex. : membre@example.org")
      expect(page).to have_field("Numéros des membres à suspendre", placeholder: "Ex. : 12, 34, 56")
      expect(page).to have_content("N’indiquez ni noms ni adresses e-mail")
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
      page.save_screenshot(Rails.root.join("tmp/screenshots/admin-access-#{width}.png"))
      find('#workspace-tab-access').send_keys(:end)
      expect(page).to have_css('#workspace-tab-audit[aria-selected="true"]')
      expect(page).to have_button("Filtrer le journal")
      expect(page).not_to have_button("Bloquer cet e-mail")
      expect(page).to have_css('[role="tabpanel"]:not([hidden])', count: 1)
      click_link "Activité", exact: true
      page.go_back
      expect(page).to have_css('#workspace-tab-audit[aria-selected="true"]')
      page.save_screenshot(Rails.root.join("tmp/screenshots/admin-overview-audit-#{width}.png"))
    end
  end

  it "prépare une sélection lisible, exige un second administrateur et bloque un e-mail avec expiration" do
    preparer = create(:user, :super_admin)
    approver = create(:user, :super_admin)
    member = create(:profile, display_name: "Camille Collectif").user
    sign_in_admin(preparer)
    visit admin_root_path(tab: "access")
    fill_in "Numéros des membres à suspendre", with: "##{member.id}"
    fill_in "Motif de la suspension", with: "Annonces frauduleuses vérifiées"
    click_button "Prévisualiser les membres"
    expect(page).to have_css('#workspace-tab-access[aria-selected="true"]')
    expect(page).to have_link("Camille Collectif (##{member.id})")
    expect(page).not_to have_button("Confirmer la suspension de ces membres")
    expect(member.reload).to be_active
    find("summary", text: "Mon espace").click
    click_button "Se déconnecter"
    sign_in_admin(approver)
    visit admin_root_path(tab: "access")
    click_button "Confirmer la suspension de ces membres"
    expect(page).to have_content("Suspension effectuée")
    expect(member.reload).to be_suspended
    expect(AuditLog.where(target: member, action: "operations.suspend", actor: approver)).to exist
    fill_in "Adresse e-mail à bloquer", with: "abus@example.org"
    page.execute_script("document.querySelector('#block-expiry').value = arguments[0]", 1.day.from_now.strftime("%Y-%m-%dT%H:%M"))
    fill_in "Motif du blocage", with: "Tentatives abusives documentées"
    click_button "Bloquer cet e-mail"
    expect(page).to have_content("Action enregistrée")
    expect(LoginBlock.blocked?("abus@example.org")).to be(true)
    click_link "Journal d’audit", exact: true
    expect(page).to have_content("Tentatives abusives documentées")
  end
end
