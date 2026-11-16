module Admin
  class SiteController < BaseController
    before_action { raise Pundit::NotAuthorizedError unless current_user.super_admin? }
    before_action :load_version, only: [ :review, :publish ]

    def index
      version = workspace_version || Studio.change!(actor: current_user, settings: {}, name: "Éditeur visuel", source: StudioVersion.current)
      options = { page: params[:page].presence || "home" }
      options[:panel] = "retention" if params[:panel] == "retention"
      options[:document] = params[:document] if ContentVersion::LEGAL_SLUGS.include?(params[:document])
      redirect_to builder_admin_site_path(version, **options), status: :see_other
    end

    def review
      prepare_review
      render layout: "studio_review"
    end

    def publish
      Studio.publish_from_review!(version: @version, actor: current_user, digest: params[:digest], live_id: params[:live_id])
      redirect_to admin_site_index_path(page: params[:page].presence || "home"), notice: "Vos modifications sont en ligne.", status: :see_other
    rescue Exchanges::Invalid, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => error
      @publication_error = error.message
      prepare_review
      render :review, layout: "studio_review", status: :unprocessable_content
    end

    private

    def prepare_review
      @area = params[:area]
      @slug = params[:page].presence || "home"
      raise ActiveRecord::RecordNotFound unless @version.available_pages.include?(@slug)
      @device = params[:device].presence_in(%w[phone tablet desktop]) || "desktop"
      @preview_width = params[:width].present? ? params[:width].to_i.clamp(320, 1920) : { "phone" => 390, "tablet" => 768 }[@device]
      @live_version = StudioVersion.current
      @review_errors = Studio.review_errors(@version)
    end

    def workspace_version
      live = StudioVersion.current
      drafts = StudioVersion.where(author: current_user, status: %w[draft validated])
      drafts = drafts.where("created_at > ?", live.published_at) if live&.published_at
      drafts.order(id: :desc).first || live
    end

    def load_version
      @version = StudioVersion.find(params[:id])
    end
  end
end
