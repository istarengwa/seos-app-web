require "rails_helper"

RSpec.describe "Disponibilité des fonctionnalités", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:member) { create(:profile).user }
  def switch(key, enabled = false)
    AppFeatures.change!(actor: super_admin, key: key, enabled: enabled, reason: "Lancement progressif", expected: AppFeatures.digest, password: "UnMotDePasseSolide!42")
  end

  it "prévisualise les conséquences sans mutation puis confirme un changement audité" do
    organization_space
    login super_admin
    get admin_features_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Fonctionnalités", "Les annonces, les échanges et le moteur de Points Services restent toujours disponibles")
    digest = AppFeatures.digest
    expect do
      post admin_features_path, params: { operation: "preview", feature: "associations", enabled: "0", reason: "Plus tard", digest: digest }
    end.not_to change(FeatureFlag, :count)
    expect(response.body).to include("Confirmer ce changement", "Missions dépendantes")
    post admin_features_path, params: { operation: "confirm", feature: "associations", enabled: "0", reason: "Plus tard", digest: digest }
    expect(response).to redirect_to(admin_features_path(tab: "community"))
    expect(AppFeatures.enabled?("associations")).to be(false)
    get admin_features_path
    expect(response.body).to include("Plus tard", "Désactivée")
    post admin_features_path, params: { operation: "confirm", feature: "associations", enabled: "1", reason: "Écran ancien", digest: digest }
    expect(response).to have_http_status(:unprocessable_content)
    expect(AppFeatures.enabled?("associations")).to be(false)
    post admin_features_path, params: { operation: "preview", feature: "associations", enabled: "2", reason: "Essai" }
    expect(response).to have_http_status(:unprocessable_content)
    post admin_features_path, params: { operation: "preview", feature: "associations", enabled: "0", reason: "" }
    expect(response).to have_http_status(:unprocessable_content)
    post admin_features_path, params: { operation: "invalid", feature: "associations", enabled: "0", reason: "Essai" }
    expect(response).to have_http_status(:unprocessable_content)
    post admin_features_path, params: { operation: "preview", feature: "points", enabled: "0", reason: "Essai" }
    expect(response).to have_http_status(:not_found)
  end

  it "retire les associations des pages et menus sans modifier les dossiers et ferme aussi les URL directes" do
    organization = organization_space
    mission = world_mission(organization: organization)
    before = [ organization.attributes, mission.attributes ]
    switch("associations")
    get community_path
    expect(response.body).not_to include("Les associations ont leur place ici", 'href="/associations"', "Proposer mon association")
    get associations_path
    expect(response).to have_http_status(:not_found)
    get association_path(organization)
    expect(response).to have_http_status(:not_found)
    get volunteer_missions_path
    expect(response).to have_http_status(:not_found)
    get sitemap_path
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(associations_url, association_url(organization), volunteer_missions_url)
    login member
    get account_root_path
    expect(response.body).not_to include('href="/compte/organisations"')
    [ account_organizations_path, organization_dashboard_path(organization_slug: organization.slug), organization_invitation_path, account_mission_applications_path ].each do |path|
      get path
      expect(response).to have_http_status(:not_found), path
    end
    expect { post account_organizations_path, params: { organization: { name: "Tentative" } } }.not_to change(Organization, :count)
    expect(response).to have_http_status(:not_found)
    get new_account_listing_path(organization_slug: organization.slug)
    expect(response).to have_http_status(:not_found)
    expect { post account_listings_path, params: { organization_slug: organization.slug, listing: { intent: "offer" } } }.not_to change(Listing, :count)
    expect(response).to have_http_status(:not_found)
    expect([ organization.reload.attributes, mission.reload.attributes ]).to eq(before)
    switch("associations", true)
    get associations_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(organization.name)
  end

  it "filtre aussi les compositions déjà enregistrées et conserve leur source pour la réactivation" do
    page = SiteDesign.default_page("communaute")
    page["canvas"] = { "version" => 1, "html" => '<div class="page"><section class="community-associations"><h1>Association composée</h1><a href="/associations">Annuaire</a></section><section><h2>Contenu principal conservé</h2></section></div>', "css" => "" }
    version = Studio.change!(actor: super_admin, name: "Composition", settings: { "site" => { "pages" => { "communaute" => page } } })
    %w[validate publish].each { |action| Studio.transition!(version: version, actor: super_admin, action: action, reason: "Composition publique") }
    source = version.settings.deep_dup
    switch("associations")
    get community_path
    expect(response.body).to include("Contenu principal conservé")
    expect(response.body).not_to include("Association composée", "Annuaire")
    expect(version.reload.settings).to eq(source)
    login super_admin
    get builder_admin_site_path(version, page: "communaute")
    expect(studio_builder_configuration.fetch("initialHtml")).to include("Association composée", 'data-app-feature-disabled="true"')
    get preview_admin_studio_path(version, page: "communaute", canvas: "1")
    expect(response.body).not_to include("Association composée")
    switch("associations", true)
    get community_path
    expect(response.body).to include("Association composée")
  end

  it "garde les dossiers consultables en lecture seule pour le super admin et les masque aux admins" do
    organization = organization_space
    switch("associations")
    login super_admin
    get admin_network_path(organization.id, section: "organizations")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(organization.name, 'class="feature-readonly"', "Consultation des données conservées")
    post admin_network_index_path, params: { operation: "review", record_id: organization.id, status: "suspended", reason: "Essai" }
    expect(response).to have_http_status(:not_found)
    expect(organization.reload).to be_verified
    post admin_network_index_path, params: { operation: "reveal", record_id: organization.id, reason: "Consulter le dossier conservé" }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(organization.legal_email)
    delete destroy_user_session_path
    login create(:user, :admin)
    get admin_root_path
    expect(response.body).not_to include("Gérer les demandes", 'href="/admin/organisations"')
    get admin_network_index_path
    expect(response).to have_http_status(:not_found)
    get admin_features_path
    expect(response).to have_http_status(:forbidden)
    post admin_features_path, params: { feature: "associations", enabled: "1" }
    expect(response).to have_http_status(:forbidden)
  end

  it "bloque les entrées de chaque module tout en préservant les pages communes et les annonces" do
    login member
    cases = {
      "chains" => [ account_chains_path, chain_invitation_path ],
      "testimonials" => [ testimonials_path, account_testimonials_path ],
      "voyage" => [ volunteer_missions_path, account_mission_applications_path, site_page_path("voyage-solidaire"), explanation_path("voyage-solidaire") ],
      "journal" => [ journal_path ], "referrals" => [ referral_invitation_path(token: "inexistant") ]
    }
    cases.each do |feature, paths|
      switch(feature)
      paths.each { |path| get path; expect(response).to have_http_status(:not_found), path }
    end
    switch("quests")
    get account_community_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Mes mises en avant")
    expect(response.body).not_to include("Mes quêtes", "Voir mes chaînes")
    switch("highlights")
    get account_community_path
    expect(response).to have_http_status(:not_found)
    [ [ account_chains_path, {} ], [ account_testimonials_path, { operation: "testimonial" } ], [ account_community_path, { operation: "quest" } ], [ account_community_path, { operation: "top" } ], [ account_trust_path, { operation: "issue" } ], [ account_points_path, { operation: "claim", kind: "share" } ], [ chain_invitation_path, {} ], [ account_mission_applications_path, {} ] ].each do |path, parameters|
      post path, params: parameters
      expect(response).to have_http_status(:not_found), path
    end
    get account_trust_path
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("Créer mon lien de parrainage", "Mon parrainage")
    switch("public_map")
    get listings_path(view: "map")
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("data-public-map", "map.js")
    [ account_points_path, new_account_listing_path, privacy_preferences_path ].each { |path| get path; expect(response).to have_http_status(:ok), path }
  end

  it "coupe Google avant le départ OAuth et protège également les callbacks" do
    switch("google_login")
    post user_google_oauth2_omniauth_authorize_path
    expect(response).to have_http_status(:not_found)
    get user_google_oauth2_omniauth_callback_path
    expect(response).to have_http_status(:not_found)
    get new_user_session_path
    expect(response.body).not_to include("Continuer avec Google")
    expect(response.body).to include("Mot de passe")
  end

  it "ne laisse aux modérateurs que les rubriques actives et réserve les anciennes preuves au super admin" do
    %w[quests chains testimonials].each { |feature| switch(feature) }
    moderator = create(:user, :admin)
    %w[community.read community.manage points.rewards].each { |permission| grant(moderator, permission) }
    login moderator
    get admin_community_index_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Mises en avant")
    expect(Nokogiri::HTML(response.body).at_css(".desktop-workspace-navigation").text).not_to include("Quêtes", "Chaînes", "Preuves de récompense")
    get admin_community_index_path(tab: "quests")
    expect(response).to have_http_status(:not_found)
    get admin_points_path
    expect(response).to have_http_status(:not_found)
    switch("highlights")
    get admin_community_index_path
    expect(response).to have_http_status(:not_found)
    delete destroy_user_session_path
    login super_admin
    get admin_community_index_path(tab: "quests")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Consultation des données conservées")
    get admin_points_path
    expect(response).to have_http_status(:ok)
    post admin_points_path, params: { operation: "review", record_id: 999, decision: "approved", reason: "Tentative" }
    expect(response).to have_http_status(:not_found)
  end

  it "ne laisse pas l’ancien journal republier un article désactivé" do
    article = create(:content_version, author: super_admin, kind: "article", slug: "article-conserve", title: "Article conservé")
    switch("journal")
    login super_admin
    get admin_workbench_path(article.id, kind: "contenus")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(article.title, "feature-readonly")
    patch admin_workbench_path(article.id, kind: "contenus"), params: { published_at: Time.current, reason: "Tentative" }
    expect(response).to have_http_status(:not_found)
    patch admin_workbench_path(article.id, kind: "contenus"), params: { operation: "reveal", published_at: Time.current, reason: "Paramètre détourné" }
    expect(response).to have_http_status(:not_found)
    expect(article.reload.published_at).to be_nil
    post admin_workbench_index_path(kind: "contenus"), params: { record: { kind: "article", slug: "nouveau", title: "Texte", body: "Contenu" } }
    expect(response).to have_http_status(:not_found)
  end

  it "ferme également les anciennes preuves liées à un module désactivé sans changer leur montant" do
    point_rules
    claim = Points::Rewards.submit!(user: member, kind: "written", evidence: "Preuve conservée du témoignage")
    quest = Achievement.create!(slug: "temoignage-optionnel", name: "Mon témoignage", description: "Joindre la preuve", event_name: "manual", reward_key: "written")
    record = Achievements.submit!(user: member, achievement: quest, evidence: "Suivi du témoignage optionnel")
    record.proof.attach(io: StringIO.new(Vips::Image.black(20, 20).write_to_buffer(".png")), filename: "preuve.png", content_type: "image/png")
    switch("testimonials")
    switch("chains")
    login member
    get account_community_path
    expect(response.body).not_to include(quest.name, record.evidence)
    get media_path(record.proof.attachment)
    expect(response).to have_http_status(:not_found)
    post account_points_path, params: { operation: "claim", kind: "chain", evidence: "Ancienne entrée" }
    expect(response).to have_http_status(:not_found)
    post account_points_path, params: { operation: "claim", kind: "video", evidence: "Ancienne entrée" }
    expect(response).to have_http_status(:not_found)
    moderator = create(:user, :admin)
    grant(moderator, "points.rewards")
    delete destroy_user_session_path
    login moderator
    get admin_points_path
    expect(response.body).not_to include(claim.evidence)
    delete destroy_user_session_path
    login super_admin
    get media_path(record.proof.attachment)
    expect(response).to have_http_status(:ok)
    get admin_community_index_path(tab: "proofs")
    expect(response.body).to include(record.evidence, "preuve conservée en lecture seule")
    get admin_points_path
    expect(response.body).to include(claim.evidence)
    expect(response.body).not_to include("Valider et créditer")
    expect do
      post admin_points_path, params: { operation: "review", record_id: claim.id, decision: "approved", reason: "Tentative" }
    end.not_to change(PointEntry, :count)
    expect(response).to have_http_status(:not_found)
    expect(claim.reload.status).to eq("pending")
  end

  it "retire les notifications désactivées des compteurs sans supprimer leur historique" do
    notice = Notification.notify!(user: member, key: "chain:old", title: "CHAINE PRIVEE")
    Notification.notify!(user: member, key: "points:core", title: "Votre solde")
    switch("chains")
    login member
    get account_notifications_path
    expect(response.body).not_to include("CHAINE PRIVEE")
    get counts_account_notifications_path
    expect(response.parsed_body["categories"]).not_to have_key("chains")
    patch open_account_notification_path(notice)
    expect(response).to have_http_status(:not_found)
    expect(Notification.find(notice.id)).to eq(notice)
  end
end
