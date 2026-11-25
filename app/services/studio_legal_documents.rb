# Legal text travels with the Studio draft; only publication creates public versions.
class StudioLegalDocuments
  FIELDS = %w[title summary body base_id].freeze

  def self.valid?(documents)
    return false unless documents.is_a?(Hash) && (documents.keys - ContentVersion::LEGAL_SLUGS).empty?
    documents.all? do |slug, fields|
      fields.is_a?(Hash) && (fields.keys - FIELDS).empty? &&
        fields["title"].is_a?(String) && fields["title"].strip.present? && fields["title"].size <= 200 &&
        fields["summary"].is_a?(String) && fields["summary"].size <= 200 &&
        fields["body"].is_a?(String) && fields["body"].strip.present? && fields["body"].size <= 30_000 &&
        (fields["base_id"].nil? || (fields["base_id"].is_a?(Integer) && ContentVersion.live.exists?(id: fields["base_id"], kind: "legal", slug: slug)))
    end
  end

  def self.for_editor(version = nil)
    ContentVersion::LEGAL_SLUGS.to_h do |slug|
      current = ContentVersion.current("legal", slug)
      document = current || LegalExample.document(slug)
      fields = document.attributes.slice("title", "summary", "body").merge("summary" => document.summary.to_s, "base_id" => current&.id)
      fields = version.legal_documents.fetch(slug, fields) if version && version.status != "published"
      [ slug, fields ]
    end
  end

  def self.preview(version, slug)
    fields = version&.legal_documents&.[](slug) if version && version.status != "published"
    return ContentVersion.new(fields.slice("title", "summary", "body").merge(kind: "legal", slug: slug)) if fields
    ContentVersion.current("legal", slug) || LegalExample.document(slug)
  end

  def self.publish!(version, actor)
    version.legal_documents.each do |slug, fields|
      current = ContentVersion.live.where(kind: "legal", slug: slug).order(version: :desc).lock.first
      unless current&.id == fields["base_id"]
        raise Exchanges::Invalid, "Le document « #{fields['title']} » a changé depuis votre copie. Rechargez-le avant de publier."
      end
      number = ContentVersion.where(kind: "legal", slug: slug).maximum(:version).to_i + 1
      document = ContentVersion.create!(fields.slice("title", "summary", "body").merge(kind: "legal", slug: slug, author: actor, version: number, published_at: Time.current))
      AuditLog.create!(actor: actor, target: document, action: "content.publish", reason: "Publication du document légal depuis le Studio", metadata: { "from" => current&.id.to_i, "to" => document.id })
    end
  end
end
