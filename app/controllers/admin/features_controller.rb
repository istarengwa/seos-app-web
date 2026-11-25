module Admin
  class FeaturesController < BaseController
    before_action { raise Pundit::NotAuthorizedError unless current_user.super_admin? }

    def index
      prepare_features
    end

    def create
      @key = params[:feature].to_s
      @definition = AppFeatures.definition(@key)
      raise Exchanges::Invalid, "Choisissez Actif ou Désactivé." unless %w[0 1].include?(params[:enabled])
      @enabled = params[:enabled] == "1"
      @reason = params[:reason].to_s.strip
      raise Exchanges::Invalid, "Précisez un motif de 1 à 500 caractères." unless @reason.size.between?(1, 500)
      if params[:operation] == "confirm"
        AppFeatures.change!(actor: current_user, key: @key, enabled: @enabled, reason: @reason, expected: params[:digest], password: params[:password])
        redirect_to admin_features_path(tab: @definition[:group]), notice: "Fonctionnalité mise à jour.", status: :see_other
      elsif params[:operation] == "preview"
        prepare_features
        raise Exchanges::Invalid, "Les réglages ont changé. Recommencez la vérification." unless params[:digest] == @feature_digest
        @confirmation = true
        render :index
      else
        raise Exchanges::Invalid, "Action inconnue."
      end
    rescue KeyError
      raise ActiveRecord::RecordNotFound
    rescue Exchanges::Invalid, ActiveRecord::StaleObjectError, ActiveRecord::RecordNotUnique => error
      @feature_error = error.message
      prepare_features
      render :index, status: :unprocessable_content
    end

    private

    def prepare_features
      @feature_values = AppFeatures.flags
      @feature_digest = AppFeatures.digest(@feature_values)
      @feature_changes = AuditLog.includes(:actor).where(action: "feature.change").order(id: :desc).limit(50)
    end
  end
end
