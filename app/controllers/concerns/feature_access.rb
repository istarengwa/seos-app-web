module FeatureAccess
  extend ActiveSupport::Concern
  included { before_action :enforce_feature_access }

  private

  def enforce_feature_access
    key = request_feature
    return unless key
    keys = Array(key)
    return if keys.any? { |feature| AppFeatures.enabled?(feature) }
    audited_reveal = controller_path == "admin/network" && action_name == "create" && params[:operation] == "reveal"
    if controller_path.start_with?("admin/") && current_user&.super_admin? && (request.get? || audited_reveal)
      @disabled_feature = keys.first
      return
    end
    raise ActiveRecord::RecordNotFound
  end

  def request_feature
    case controller_path
    when "associations", "account/organizations", "organizations/dashboard", "organization_invitations" then "associations"
    when "volunteer_missions", "account/mission_applications" then "voyage"
    when "account/chains", "chain_invitations" then "chains"
    when "account/listings"
      "associations" if %w[new create].include?(action_name) && params[:organization_slug].present?
    when "referral_invitations" then "referrals"
    when "testimonials", "account/testimonials" then "testimonials"
    when "contents"
      return "voyage" if params[:kind] == "page" && params[:slug] == "voyage-solidaire"
      "journal" if action_name == "index" || params[:kind] == "article"
    when "site" then "voyage" if params[:slug] == "voyage-solidaire"
    when "account/community"
      if request.get?
        %w[quests highlights]
      else
        { "quest" => "quests", "top" => "highlights", "withdraw_top" => "highlights", "testimonial" => "testimonials", "withdraw_testimonial" => "testimonials" }[params[:operation]]
      end
    when "account/trust"
      "referrals" if !request.get? && (%w[issue claim primary object].include?(params[:operation]) || params[:referral_id].present?)
    when "account/points"
      if !request.get? && params[:operation] == "claim"
        return "testimonials" if %w[written video].include?(params[:kind]) && !AppFeatures.enabled?("testimonials")
        return "chains" if params[:kind] == "chain" && !AppFeatures.enabled?("chains")
        "quests"
      end
    when "admin/network"
      return if params[:operation] == "flag" || params[:section] == "settings"
      params[:section] == "missions" || params[:operation].to_s.start_with?("mission") ? "voyage" : "associations"
    when "admin/community"
      tab = params[:tab].presence || "quests"
      unless request.get?
        tab = { "quest" => "quests", "quest_update" => "quests", "review_quest" => "proofs", "review_top" => "highlights", "review_testimonial" => "testimonials", "chain" => "chains" }[params[:operation]]
      end
      AppFeatures::COMMUNITY_TABS[tab] unless request.get? && params[:tab].blank?
    when "admin/points"
      if !request.get? && (claim = PointRewardClaim.find_by(id: params[:record_id]))
        return "testimonials" if %w[written video].include?(claim.kind) && !AppFeatures.enabled?("testimonials")
        return "chains" if claim.kind == "chain" && !AppFeatures.enabled?("chains")
      end
      "quests"
    when "admin/workbench"
      if params[:kind] == "contenus" && action_name != "index"
        kind = params.dig(:record, :kind) || ContentVersion.find_by(id: params[:id].presence || params[:from])&.kind
        "journal" if kind == "article"
      end
    end
  end
end
