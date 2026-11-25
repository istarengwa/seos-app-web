require "rails_helper"
RSpec.describe "Accessibilité des outils de lancement", type: :system do
  it "offre les préférences, droits et outils admin sur mobile et ordinateur" do
    admin = create(:user, :super_admin)
    visit new_user_session_path
    fill_in "E-mail", with: admin.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    [ privacy_preferences_path, account_privacy_path, admin_privacy_index_path, admin_operations_path ].each_with_index do |path, index|
      visit path
      [ 375, 1440 ].each do |width|
        resize_viewport(width)
        expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true), path
        expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21aa, :wcag22aa)
        page.save_screenshot(Rails.root.join("tmp/screenshots/phase7-#{index}-#{width}.png"))
      end
    end
  end
end
