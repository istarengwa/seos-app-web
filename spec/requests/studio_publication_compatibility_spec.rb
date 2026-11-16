require "rails_helper"

RSpec.describe "Pages publiques et aperçus après migration vers la V2", type: :request do
  let(:admin) { create(:user, :super_admin) }

  it "sert les compositions publiées sur les adresses publiques existantes" do
    version = Studio.change!(actor: admin, name: "Pages publiques", settings: {
      "site" => { "pages" => %w[don notre-equipe].to_h do |slug|
        [ slug, { "title" => "Présentation #{slug}", "blocks" => [ { "id" => "intro", "template" => "text", "values" => { "body" => "Une page composée avec la V2 : #{slug}." } } ] } ]
      end }
    })
    Studio.publish_from_review!(version: version, actor: admin, digest: version.digest, live_id: "")
    [ explanation_path("don"), explanation_path("notre-equipe"), site_page_path("notre-equipe") ].each do |path|
      get path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Une page composée avec la V2")
    end
    [ explanation_path("inconnue"), legal_path("inconnue") ].each do |path|
      get path
      expect(response).to have_http_status(:not_found)
    end
  end

  it "prévisualise les pages système par défaut sans altérer les contenus éditoriaux conservés" do
    content = create(:content_version, author: admin, kind: "page", slug: "don", title: "Le don éditorial", summary: "Notre présentation", body: "Le contenu historique reste disponible.", published_at: Time.current)
    draft = Studio.change!(actor: admin, name: "Aperçu de compatibilité", settings: {})
    login admin
    get builder_admin_site_path(draft, page: "don")
    expect(response).to have_http_status(:ok)
    get preview_admin_studio_path(draft, page: "don", canvas: "1")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Le don", 'data-studio-block="don-0"')
    post builder_preview_admin_site_path(draft), params: { document: {}.to_json, page: "don" }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Le don")
    get preview_admin_studio_path(draft, page: "home", canvas: "1")
    expect(response).to have_http_status(:ok)
    get preview_admin_studio_path(draft, page: "inconnue", canvas: "1")
    expect(response).to have_http_status(:not_found)
    get preview_admin_studio_path(draft, page: "points", canvas: "1")
    expect(response).to have_http_status(:not_found)
    expect(draft.reload.settings).to eq({})
    expect(content.reload.body).to eq("Le contenu historique reste disponible.")
  end

  it "distingue les articles publiés, les brouillons et les pages inconnues sans Studio publié" do
    article = create(:content_version, author: admin, kind: "article", slug: "rencontre", title: "Rencontres solidaires", published_at: Time.current)
    create(:content_version, author: admin, kind: "article", slug: "secret", title: "Brouillon privé", published_at: nil)
    get article_path(article.slug)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(article.title)
    get article_path("secret")
    expect(response).to have_http_status(:not_found)
    get explanation_path("inconnue")
    expect(response).to have_http_status(:not_found)
  end
end
