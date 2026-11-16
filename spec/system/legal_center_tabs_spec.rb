require "rails_helper"
RSpec.describe "Édition du centre légal", type: :system do
  it "permet au super admin de modifier la présentation dans le Studio sans publication immédiate" do
    admin = create(:user, :super_admin)
    version = Studio.change!(actor: admin, name: "Centre à personnaliser", settings: {})
    visit new_user_session_path
    fill_in "E-mail", with: admin.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    visit builder_admin_site_path(version, page: "legal")
    within_frame(find(".gjs-frame")) do
      find('.legal-center h1').double_click
      find('[contenteditable="true"]').send_keys([ :control, 'a' ], "Nos règles et vos choix")
      find("footer").click
    end
    click_button "Enregistrer", exact: true
    expect(page).to have_content("Modifications enregistrées")
    expect(StudioVersion.last.site.dig("pages", "legal", "canvas", "html")).to include("Nos règles et vos choix")
    visit legal_center_path
    expect(page).not_to have_css('h1', text: "Nos règles et vos choix")
  end
end
