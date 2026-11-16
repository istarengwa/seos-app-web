require "rails_helper"

RSpec.describe "Visibilité du mot de passe", type: :system do
  it "centre un œil fermé, puis ouvre et referme l’œil avec le mot de passe, à la souris et au clavier" do
    [ 375, 1440 ].each do |width|
      resize_viewport(width)
      visit new_user_session_path
      input = find('input[autocomplete="current-password"]')
      input.fill_in with: "UnMotDePasseSolide!42"
      button = find('button[aria-label="Afficher le mot de passe"]')
      expect(input[:type]).to eq("password")
      expect(button["aria-pressed"]).to eq("false")
      expect(button["aria-controls"]).to eq(input[:id])
      expect(button).to have_css('[data-password-visibility-target="closedIcon"]', visible: true)
      expect(button).not_to have_css('[data-password-visibility-target="openIcon"]', visible: true)
      input_box = input.native.rect
      button_box = button.native.rect
      expect(button_box.y + button_box.height / 2.0).to be_within(1).of(input_box.y + input_box.height / 2.0)
      expect(button_box.width).to be >= 44
      expect(button_box.height).to be >= 44
      expect(button_box.x + button_box.width).to be < input_box.x + input_box.width
      page.save_screenshot(Rails.root.join("tmp/screenshots/password-closed-#{width}.png"))
      button.click
      expect(input[:type]).to eq("text")
      expect(input.value).to eq("UnMotDePasseSolide!42")
      expect(button["aria-label"]).to eq("Masquer le mot de passe")
      expect(button["aria-pressed"]).to eq("true")
      expect(button).to have_css('[data-password-visibility-target="openIcon"]', visible: true)
      expect(button).not_to have_css('[data-password-visibility-target="closedIcon"]', visible: true)
      page.save_screenshot(Rails.root.join("tmp/screenshots/password-open-#{width}.png"))
      button.send_keys(:enter)
      expect(input[:type]).to eq("password")
      expect(button["aria-label"]).to eq("Afficher le mot de passe")
      expect(button).to have_css('[data-password-visibility-target="closedIcon"]', visible: true)
    end
  end

  it "garde chaque mot de passe indépendant dans les réglages et la confirmation du compte" do
    user = create(:user)
    visit new_user_session_path
    fill_in "E-mail", with: user.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    visit edit_user_registration_path
    expect(page).to have_css('.password-control input[type="password"]', count: 3)
    within(find('input[autocomplete="current-password"]').find(:xpath, "..")) do
      find('button[aria-label="Afficher le mot de passe"]').click
      expect(page).to have_css('input[type="text"]')
    end
    expect(page).to have_css('.password-control input[type="password"]', count: 2)
    visit new_account_reauthentication_path
    expect(page).to have_css('input[type="password"]')
    button = find('button[aria-label="Afficher le mot de passe"]')
    input = find('input[type="password"]')
    expect(button["aria-controls"]).to eq(input[:id])
    expect(input.native.css_value("padding-right").to_f).to be >= button.native.rect.width + 5
    button.click
    expect(page).to have_css('input[type="text"]')
    expect(button).to have_css('[data-password-visibility-target="openIcon"]', visible: true)
  end
end
