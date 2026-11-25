module Admin
  class PointsController < BaseController
    before_action :require_points_permission

    def index
      @claims = PointRewardClaim.includes(:user, :point_rule_version).order(id: :desc).limit(100)
      @claims = @claims.select { |claim| AppFeatures.proof_available?(claim.kind) } unless current_user.super_admin?
    end

    def create
      raise Exchanges::Invalid, "Action inconnue." unless params[:operation] == "review"
      Points::Rewards.review!(PointRewardClaim.find(params[:record_id]), actor: current_user, decision: params[:decision], reason: params[:reason])
      redirect_to admin_points_path, notice: "Action enregistrée.", status: :see_other
    end

    private

    def require_points_permission
      raise Pundit::NotAuthorizedError unless current_user.permission?("points.rewards")
    end
  end
end
