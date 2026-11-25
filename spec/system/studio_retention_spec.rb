require "rails_helper"

RSpec.describe "Réglages de conservation dans le Studio", type: :system do
  def sign_in_studio(user)
    visit new_user_session_path
    fill_in "E-mail", with: user.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
  end

  it "modifie les durées sans perdre le texte en cours, puis fait confirmer la version" do
    author = create(:user, :super_admin)
    approver = create(:user, :super_admin)
    version = Studio.change!(actor: author, settings: {}, name: "Brouillon légal")
    sign_in_studio(author)
    visit builder_admin_site_path(version, page: "legal")
    fill_in "Titre du document", with: "Mon texte en cours"
    click_button "Durées de conservation des données"
    expect(page).to have_css("dialog[open]")
    [ 1440, 375 ].each do |width|
      resize_viewport(width)
      expect(find("dialog").native.rect.width).to be <= width
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
      page.save_screenshot(Rails.root.join("tmp/screenshots/studio-retention-#{width}.png"))
    end
    resize_viewport(1440)
    fill_in "Nom de cette version", with: "Durées de notre collectif"
    fill_in "Notifications (jours)", with: 90
    check "Ces durées ont été validées juridiquement pour les données indiquées."
    click_button "Créer la version de conservation"
    expect(page).to have_css(".studio-retention-version h4", text: "Durées de notre collectif")
    within(".studio-retention-version") do
      fill_in "Motif de la simulation", with: "Vérification du collectif"
      click_button "Simuler ces durées"
    end
    expect(page).to have_content("Simulation prête")
    expect(page).not_to have_button("Confirmer ces durées")
    click_button "Fermer", exact: true
    expect(page).to have_field("Titre du document", with: "Mon texte en cours")
    expect(page).to have_content("Modifications non enregistrées")
    click_button "Enregistrer", exact: true
    expect(page).to have_content("Modifications enregistrées")
    visit admin_root_path
    find("summary", text: "Mon espace").click
    click_button "Se déconnecter"
    sign_in_studio(approver)
    visit admin_privacy_index_path
    expect(page).to have_css("dialog[open]")
    fill_in "Motif de confirmation", with: "Durées examinées et approuvées"
    click_button "Confirmer ces durées"
    expect(page).to have_css(".studio-retention-version strong", text: "Confirmée")
    expect(RetentionPolicyVersion.last).to have_attributes(status: "published", approved_by: approver)
    expect(RetentionPolicyVersion.last.rules["notifications"]).to eq(90)
  end
end
