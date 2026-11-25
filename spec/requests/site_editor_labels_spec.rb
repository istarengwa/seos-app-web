require "rails_helper"

RSpec.describe "Présentation des outils du Studio V2", type: :request do
  let(:admin) { create(:user, :super_admin) }

  it "présente les compositions disponibles avec des noms compréhensibles" do
    login admin
    version = Studio.change!(actor: admin, name: "Modèles", settings: {})
    get builder_admin_site_path(version)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Compositions", "Éléments", "Enregistrer", "Vérifier et publier")
    templates = studio_builder_configuration.fetch("templates")
    expect(templates.keys).to match_array(SiteDesign.editable_templates.keys)
    expect(templates.values).to all(include("name" => a_string_matching(/[[:alpha:]]/)))
  end

  it "conserve les valeurs des compositions existantes lors d’une sauvegarde V2" do
    login admin
    block = { "id" => "hero", "template" => "home-0", "values" => { "text-6" => "⌕", "text-5" => "Notre présentation", "text-4" => "ensemble" } }
    version = Studio.change!(actor: admin, name: "Accueil", settings: { "site" => { "pages" => { "home" => { "title" => "Accueil", "blocks" => [ block ] } } } })
    get builder_admin_site_path(version)
    document = studio_builder_configuration.fetch("settings")
    document.dig("site", "pages", "home", "blocks", 0, "values")["text-4"] = "la solidarité"
    saved = save_studio_version(version, document)
    expect(saved.site.dig("pages", "home", "blocks", 0, "values")).to include("text-6" => "⌕", "text-5" => "Notre présentation", "text-4" => "la solidarité")
    expect(version.reload.site.dig("pages", "home", "blocks", 0, "values", "text-4")).to eq("ensemble")
  end
end
