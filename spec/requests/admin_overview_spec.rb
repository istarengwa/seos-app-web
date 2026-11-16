require "rails_helper"

RSpec.describe "Vue d’ensemble et accès des membres", type: :request do
  let(:admin) { create(:user, :super_admin) }

  it "réunit les outils en onglets et retire la supervision, les registres et les purges" do
    login admin
    get admin_root_path(tab: "access")
    document = Nokogiri::HTML(response.body)
    expect(document.css(".admin-overview-tabs a").map(&:text)).to eq([ "Activité", "Outils de gestion", "Accès des membres", "Demandes de données", "Journal d’audit" ])
    expect(document.at_css("#workspace-access")["hidden"]).to be_nil
    expect(document.at_css("#workspace-activity")["hidden"]).not_to be_nil
    expect(document.at_css("#block-email")["placeholder"]).to eq("Ex. : membre@example.org")
    expect(document.at_css("#bulk-member-ids")["placeholder"]).to eq("Ex. : 12, 34, 56")
    expect(response.body).not_to include("Explorer les registres", "Indexation et robots", "Supervision et registres")
    expect(document.at_css(".desktop-workspace-navigation").text).not_to include("Supervision")
    get admin_privacy_index_path
    expect(response.body).not_to include("Purges", "Prévisualiser les données concernées", "Seconde approbation et purge")
    expect do
      post admin_privacy_index_path, params: { operation: "preview_purge", reason: "Ancien formulaire" }
    end.not_to change(PrivacyRun, :count)
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "ne rend pas les formulaires réservés au super-admin, même avec un onglet forgé" do
    moderator = create(:user, :admin)
    grant(moderator, "operations.manage")
    grant(moderator, "audit.read")
    AuditLog.create!(actor: admin, target: admin, action: "financial.private", reason: "SECRET FINANCIER")
    login moderator
    get admin_root_path(tab: "access")
    document = Nokogiri::HTML(response.body)
    expect(document.css(".admin-overview-tabs a").map(&:text)).to eq([ "Activité", "Outils de gestion", "Journal d’audit" ])
    expect(response.body).not_to include("block-email", "bulk-member-ids", "SECRET FINANCIER")
    expect(document.at_css("#workspace-activity")["hidden"]).to be_nil
    get admin_operations_path(tab: "actions")
    expect(response).to have_http_status(:forbidden)
    post admin_operations_path, params: { operation: "block", email: "membre@example.org" }
    expect(response).to have_http_status(:forbidden)
  end

  it "accepte les numéros indiqués dans l’aide et refuse les noms ou un numéro mal saisi" do
    member = create(:profile, display_name: "Camille à vérifier").user
    other = create(:user)
    login admin
    [ "Camille", "membre@example.org", "#{member.id}invalide" ].each do |ids|
      expect do
        post admin_operations_path, params: { operation: "preview", ids: ids, reason: "Abus constaté" }
      end.not_to change(BulkOperation, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Indiquez les numéros des membres")
    end
    post admin_operations_path, params: { operation: "preview", ids: "##{member.id}, #{other.id}; ##{member.id}", reason: "Signalements examinés" }
    expect(response).to redirect_to(admin_root_path(tab: "access"))
    expect(BulkOperation.last.targets.keys).to match_array([ member.id.to_s, other.id.to_s ])
    expect(member.reload).to be_active
    follow_redirect!
    expect(response.body).to include("Camille à vérifier", "Un autre super administrateur doit ouvrir cet onglet")
    get admin_operations_path(tab: "actions")
    expect(response).to redirect_to(admin_root_path(tab: "access"))
  end

  it "garde l’onglet d’audit, la période et le filtre dans la pagination" do
    21.times { AuditLog.create!(actor: admin, target: admin, action: "user.promoted_admin", reason: "Trace de contrôle") }
    login admin
    get admin_root_path(tab: "audit", period: 7, audit_event: "user.promoted_admin", audit_page: 2)
    document = Nokogiri::HTML(response.body)
    expect(document.at_css("#workspace-audit")["hidden"]).to be_nil
    expect(document.css("#journal-audit tbody tr").size).to eq(1)
    href = document.at_css("#journal-audit .pagination a")["href"]
    expect(href).to include("tab=audit", "period=7", "audit_event=user.promoted_admin")
  end

  it "autorise les pages publiques aux robots de recherche et d’IA malgré une ancienne politique" do
    CrawlerPolicy.create!(author: admin, search_enabled: false, training_enabled: false)
    get "/robots.txt"
    expect(response).to have_http_status(:ok)
    groups = response.body.split(/\n\n+/).reject { |group| group.start_with?("Sitemap:") }
    expect(groups.size).to eq(6)
    groups.each do |group|
      expect(group).to include("Allow: /\n", "Disallow: /compte\n", "Disallow: /admin\n", "Disallow: /auth\n")
      expect(group).not_to match(/^Disallow: \/$/)
    end
    [ root_path, partnership_page_path, legal_center_path ].each do |path|
      get path
      expect(Nokogiri::HTML(response.body).at_css('meta[name="robots"]')["content"]).to eq("index, follow"), path
    end
    post privacy_preferences_path, params: { choice: "reject" }
    get legal_center_path
    expect(response.headers["X-Robots-Tag"]).to include("noindex")
    expect(response.headers["Cache-Control"]).to include("no-store")
    login admin
    get admin_root_path
    expect(response.headers["X-Robots-Tag"]).to include("noindex")
    expect(Nokogiri::HTML(response.body).at_css('meta[name="robots"]')["content"]).to eq("noindex, nofollow")
    expect do
      post admin_operations_path, params: { operation: "crawlers", search_enabled: "0", training_enabled: "0", reason: "Ancien formulaire" }
    end.not_to change(CrawlerPolicy, :count)
    expect(response).to have_http_status(:unprocessable_content)
  end
end
