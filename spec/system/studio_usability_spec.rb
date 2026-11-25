require "rails_helper"
RSpec.describe "Pied de page du site", type: :system do
  def sign_in_admin
    admin = create(:user, :super_admin)
    visit new_user_session_path
    fill_in "E-mail", with: admin.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    admin
  end

  def expect_footer_at_bottom
    measurements = page.evaluate_script(<<~JS)
      (() => {
        const footer = document.querySelector('body > footer').getBoundingClientRect();
        const main = document.querySelector('#main-content').getBoundingClientRect();
        return { bottom: footer.bottom + scrollY, top: footer.top, mainBottom: main.bottom,
          height: innerHeight, documentHeight: document.documentElement.scrollHeight };
      })()
    JS
    expect(measurements["bottom"]).to be >= measurements["height"] - 1
    expect((measurements["documentHeight"] - measurements["bottom"]).abs).to be <= 1
    expect(measurements["top"]).to be >= measurements["mainBottom"] - 1
  end

  it "place le pied de page en bas des pages courtes et après les contenus longs" do
    admin = sign_in_admin
    version = Studio.change!(actor: admin, name: "Page courte", settings: { "site" => { "pages" => { "courte" => { "title" => "Bienvenue", "blocks" => [ { "id" => "texte", "template" => "text", "values" => { "title" => "Bienvenue", "body" => "Notre association vous accueille." } } ] } } } })
    Studio.publish_from_review!(version: version, actor: admin, digest: version.digest, live_id: "")
    [ 375, 1440 ].each do |width|
      resize_viewport(width, height: 1400)
      [ site_page_path("courte"), root_path, account_root_path, admin_root_path ].each do |path|
        visit path
        expect_footer_at_bottom
        expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      end
      visit site_page_path("courte")
      if width == 1440
        expect(page.evaluate_script("Math.abs(document.querySelector('body > footer').getBoundingClientRect().bottom - innerHeight)")).to be <= 1
      end
      page.save_screenshot(Rails.root.join("tmp/screenshots/footer-bottom-#{width}.png"))
    end
  end
end
