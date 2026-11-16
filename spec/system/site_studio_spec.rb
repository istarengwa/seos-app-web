require "rails_helper"

RSpec.describe "Publication depuis le Studio V2", type: :system do
  it "ajoute un élément, relit le brouillon et publie la page depuis le constructeur" do
    admin = create(:user, :super_admin)
    version = Studio.change!(actor: admin, name: "Page à composer", settings: {
      "site" => { "pages" => { "home" => { "title" => "Accueil", "blocks" => [ { "id" => "intro", "template" => "text", "values" => { "title" => "Bienvenue", "body" => "Notre communauté vous accueille." } } ] } } }
    })
    visit new_user_session_path
    fill_in "E-mail", with: admin.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    visit admin_site_index_path
    expect(page).to have_content("Studio V2")
    expect(page).to have_css(".gjs-block", minimum: 8, visible: :all)
    first(".gjs-block", text: "Titre").find(".visual-template-add").click
    within_frame(find(".gjs-frame")) do
      expect(page).to have_css("h2", text: "Votre nouveau titre")
    end
    click_button "Vérifier et publier"
    expect(page).to have_css("h1", text: "Vérifier avant de mettre en ligne")
    draft = StudioVersion.last
    expect(draft.id).not_to eq(version.id)
    expect(draft.status).to eq("draft")
    expect(page).to have_link("← Revenir aux modifications", href: builder_admin_site_path(draft, page: "home"))
    within_frame(find("iframe")) { expect(page).to have_css("h2", text: "Votre nouveau titre") }
    click_button "Enregistrer et publier"
    expect(page).to have_current_path(builder_admin_site_path(draft, page: "home"))
    expect(draft.reload.status).to eq("published")
    visit root_path
    expect(page).to have_css("h2", text: "Votre nouveau titre")
    expect(version.reload.status).to eq("draft")
  end
end
