class LegalCenterController < ApplicationController
  before_action { response.headers["Cache-Control"] = "no-store" }
  def show
    @slug = "legal"
    @page = StudioVersion.current&.site&.dig("pages", "legal") || SiteDesign.default_page("legal")
    @consent = CookieConsent.where(visitor_digest: Digest::SHA256.hexdigest(cookies.signed[:privacy_visitor].to_s), version: CookieConsent::VERSION).where("expires_at > ?", Time.current).order(id: :desc).first
    @indexable = @consent.nil?
    @canonical = legal_center_url
    private_response if @consent
    render "site/show"
  end
end
