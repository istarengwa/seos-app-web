require "rails_helper"

RSpec.describe "Documents légaux du Studio", type: :request do
  let(:admin) { create(:user, :super_admin) }
  let(:source) { Studio.change!(actor: admin, name: "Documents", settings: {}) }
  let(:fields) { { "title" => "Nos conditions personnalisées", "summary" => "Les règles de notre collectif", "body" => "## Participer\n\nLe respect est notre première règle.", "base_id" => nil } }

  before { login admin }

  it "enregistre un texte privé, le prévisualise en taille réelle puis publie une version légale" do
    draft = save_studio_version(source, { "legal_documents" => { "cgu" => fields } }, page: "legal")
    expect(ContentVersion.where(kind: "legal")).not_to exist
    get legal_center_path
    expect(response.body).not_to include(fields["title"])
    get preview_admin_studio_path(draft, page: "legal", canvas: "1")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(fields["title"], "Le respect est notre première règle.", "Brouillon du Studio · Non publié")
    expect(response.body).not_to include("Modifier ce document")
    get review_admin_site_path(draft, page: "legal", width: 555)
    expect(response.body).to include('class="studio-review"', 'data-studio-review-width-value="555"', "Document légal : Nos conditions personnalisées")
    expect(response.body).not_to include('class="side-menu admin-sidebar"')
    post publish_admin_site_path(draft), params: { digest: draft.digest, live_id: "", page: "legal" }
    expect(response).to have_http_status(:see_other)
    document = ContentVersion.current("legal", "cgu")
    expect(document).to have_attributes(title: fields["title"], body: fields["body"], author: admin, version: 1)
    expect(AuditLog.where(target: document, action: "content.publish")).to exist
    get legal_center_path
    expect(response.body).to include(fields["title"])
    copy = Studio.change!(actor: admin, name: "Nouvelle page", source: draft.reload, settings: {})
    expect(copy.legal_documents).to eq({})
  end

  it "refuse les textes incomplets, les références étrangères et les documents inconnus" do
    foreign = create(:content_version, author: admin, kind: "legal", slug: "cookies", published_at: Time.current)
    invalid = [ { "inconnu" => fields }, { "cgu" => fields.merge("title" => "") }, { "cgu" => fields.merge("body" => " ") }, { "cgu" => fields.merge("body" => "a" * 30_001) }, { "cgu" => fields.merge("base_id" => foreign.id) }, { "cgu" => fields.merge("html" => "<script>bad()</script>") }, [] ]
    invalid.each do |documents|
      source
      expect do
        post builder_save_admin_site_path(source), params: { document: { "legal_documents" => documents }.to_json, digest: source.digest }
      end.not_to change { [ StudioVersion.count, AuditLog.count, ContentVersion.count ] }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  it "refuse une publication obsolète sans modifier le site ni les autres documents" do
    original = create(:content_version, author: admin, kind: "legal", slug: "cgu", published_at: Time.current)
    draft = save_studio_version(source, { "legal_documents" => { "cookies" => fields.merge("title" => "Nos cookies"), "cgu" => fields.merge("base_id" => original.id) } }, page: "legal")
    current = create(:content_version, author: admin, kind: "legal", slug: "cgu", version: 2, title: "Correction publiée ailleurs", published_at: Time.current)
    expect do
      post publish_admin_site_path(draft), params: { digest: draft.digest, live_id: "", page: "legal" }
    end.not_to change { [ ContentVersion.count, AuditLog.count ] }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("a changé depuis votre copie", 'class="studio-review"')
    expect(draft.reload.status).to eq("draft")
    expect(ContentVersion.current("legal", "cgu")).to eq(current)
    expect(StudioVersion.current).to be_nil
    get builder_admin_site_path(draft, page: "legal")
    configuration = studio_builder_configuration
    expect(configuration.dig("legalDocuments", "cgu", "base_id")).to eq(original.id)
    expect(configuration.dig("publishedLegalDocuments", "cgu", "base_id")).to eq(current.id)
  end

  it "réserve aussi le changement des textes légaux au super-admin au niveau du service" do
    actor = create(:user, :admin)
    grant(actor, "content.manage")
    expect { Studio.change!(actor: actor, name: "Tentative", settings: { "legal_documents" => { "cgu" => fields } }) }.to raise_error(Pundit::NotAuthorizedError)
  end

  it "préserve les formes SVG des vagues sans laisser passer les scripts" do
    html = '<div class="site-transition"><svg viewBox="0 0 120 1200"><rect width="120" height="1200" fill="#ffffff"/><g transform="matrix(0 1 -1 0 120 0)"><path d="M0 45 Q600 120 1200 45" fill="#cdae4f"/></g><script>alert(1)</script></svg></div>'
    clean = SiteCanvasDocument.sanitize_html(html)
    expect(clean).to include("<rect", "<g", "matrix(0 1 -1 0 120 0)", "#cdae4f")
    expect(clean).not_to include("script", "alert")
  end
end
