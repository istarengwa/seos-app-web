module Admin
  class OperationsController < BaseController
    before_action -> { authorize :administration, :super_admin? }
    def index
      redirect_to admin_root_path(tab: params[:tab] == "actions" ? "access" : "activity"), status: :see_other
    end
    def create
      case params[:operation]
      when "preview"
        Operations.preview!(actor: current_user, ids: params[:ids].to_s.split(/[\s,;]+/), reason: params[:reason])
      when "execute"
        Operations.execute!(operation: BulkOperation.find(params[:record_id]), actor: current_user)
      when "block"
        raise Pundit::NotAuthorizedError unless current_user.super_admin?
        email = params[:email].to_s.strip.downcase
        raise Exchanges::Invalid, "Saisissez une adresse e-mail valide, par exemple membre@example.org." unless email.match?(URI::MailTo::EMAIL_REGEXP)
        raise Exchanges::Invalid, "L’adresse e-mail d’un administrateur ne peut pas être bloquée." if User.where(email: email, role: %w[admin super_admin]).exists?
        LoginBlock.transaction do
          record = LoginBlock.create!(email_digest: LoginBlock.digest(email), actor: current_user, reason: params[:reason], expires_at: params[:expires_at])
          AuditLog.create!(actor: current_user, target: record, action: "operations.block", reason: params[:reason])
        end
      else raise Exchanges::Invalid, "Action inconnue."
      end
      redirect_to admin_root_path(tab: "access"), notice: "Action enregistrée.", status: :see_other
    end
    def user
      raise Pundit::NotAuthorizedError unless current_user.permission?("users.read")
      @user = User.find(params[:id])
      if request.post?
        raise Pundit::NotAuthorizedError unless current_user.super_admin?
        AuditLog.create!(actor: current_user, target: @user, action: "user.sensitive_reveal", reason: params[:reason])
        @revealed = true
      end
    end
  end
end
