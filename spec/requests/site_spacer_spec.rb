require "rails_helper"

RSpec.describe "Sections vides du Studio", type: :request do
  it "ajoute, dimensionne et publie un espace vide sans texte visible" do
    admin = create(:user, :super_admin)
    login admin
    source = Studio.change!(actor: admin, settings: {}, name: "Espaces")
    page = SiteDesign.default_page("communaute")
    page["blocks"] << { "id" => "space", "template" => "spacer", "values" => { "height" => "240", "mobile_height" => "64" } }
    post builder_save_admin_site_path(source), params: { document: { "site" => { "pages" => { "communaute" => page } } }.to_json, digest: source.digest, page: "communaute" }
    expect(response).to have_http_status(:ok)
    version = StudioVersion.last
    %w[validate publish].each { |action| Studio.transition!(version: version, actor: admin, action: action, reason: "Vérifier les espacements") }
    get community_path
    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css(".site-spacer").text).to eq("")
    expect(doc.css("style").text).to include("height:240px", "height:64px")
    expect(source.reload.site).to eq({})
  end

  it "refuse des dimensions invalides ou du CSS injecté" do
    block = { "id" => "space", "template" => "spacer", "values" => {} }
    expect(SiteDesign.valid_block?(block)).to be(true)
    %w[0 -1 1201 12.5 20px 20\;color:red].each do |value|
      expect(SiteDesign.valid_block?(block.merge("values" => { "height" => value }))).to be(false)
    end
  end
end
