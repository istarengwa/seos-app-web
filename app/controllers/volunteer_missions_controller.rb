class VolunteerMissionsController < ApplicationController
  before_action do
    @indexable = true
    @canonical = request.base_url + request.path
  end
  before_action { raise ActiveRecord::RecordNotFound unless FeatureFlag.voyage_enabled? }
  def index
    @page = StudioVersion.current&.site&.dig("pages", "voyage-solidaire") || SiteDesign.default_page("voyage-solidaire")
  end
  def show
    @mission = VolunteerMission.find_by!(slug: params[:slug])
    raise ActiveRecord::RecordNotFound unless @mission.publicly_visible?
  end
end
