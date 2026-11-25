require "rails_helper"
RSpec.describe "Fondations publiques", :"F-001", type: :request do
  it "sert un accueil français sans donnée de membre ni fournisseur externe" do
    user = create(:user)
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('lang="fr"', "Points Services", "application")
    expect(response.body).not_to include(user.email, "fonts.googleapis", "leaflet", "stripe.com")
  end

  it "répond au contrôle de santé" do
    get rails_health_check_path
    expect(response).to have_http_status(:ok)
  end

  it "renvoie une vraie 404 pour une route inconnue" do
    get "/page-inconnue"
    expect(response).to have_http_status(:not_found)
  end

  it "n'ouvre aucune route d'upload avant le pipeline média sécurisé" do
    post "/rails/active_storage/direct_uploads", params: { blob: { filename: "injection.html", content_type: "text/html" } }
    expect(response).to have_http_status(:not_found)
    expect(ActiveStorage::Blob.count).to eq(0)
  end

  it "impose une CSP sans fournisseur externe" do
    get root_path
    expect(response.headers["Content-Security-Policy"]).to include("default-src 'self'", "object-src 'none'", "frame-ancestors 'none'")
  end

  it "garde le nonce CSP pendant la navigation Turbo et l’isole entre sessions" do
    get root_path
    nonce = Nokogiri::HTML(response.body).at_css('meta[name="csp-nonce"]')["content"]
    expect(nonce).to be_present
    get new_user_session_path, headers: { "Turbo-Visit" => "true" }
    expect(response.headers["Content-Security-Policy"]).to include("'nonce-#{nonce}'")
    expect(Nokogiri::HTML(response.body).at_css('meta[name="csp-nonce"]')["content"]).to eq(nonce)
    other_session = ActionDispatch::Integration::Session.new(Rails.application)
    other_session.get root_path
    expect(other_session.response.headers["Content-Security-Policy"]).not_to include("'nonce-#{nonce}'")
  end

  it "conserve des générateurs exclusivement RSpec" do
    expect(Rails.application.config.generators.options[:rails][:test_framework]).to eq(:rspec)
    expect(Rails.root.join("test")).not_to exist
  end
end
