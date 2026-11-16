module Admin
  class DashboardController < BaseController
    def show
      @overview_tabs = [ [ "activity", "Activité" ], [ "tools", "Outils de gestion" ] ]
      @overview_tabs << [ "access", "Accès des membres" ] if current_user.super_admin?
      @overview_tabs << [ "data", "Demandes de données" ] if current_user.permission?("privacy.manage")
      @overview_tabs << [ "audit", "Journal d’audit" ] if current_user.permission?("audit.read")
      fallback = params[:audit_event].present? || params[:audit_page].present? ? "audit" : "activity"
      @active_tab = (params[:tab].presence || fallback).presence_in(@overview_tabs.map(&:first)) || "activity"
      @activity = AdminActivity.new(period: params[:period], super_admin: current_user.super_admin?)
      load_audit_logs if current_user.permission?("audit.read")
      @requests = DataRequest.includes(:provider_erasure_tasks, user: :profile).order(:response_due_at).limit(100) if current_user.permission?("privacy.manage")
      if current_user.super_admin?
        @operations = BulkOperation.order(id: :desc).limit(20)
        @operation_members = User.includes(:profile).where(id: @operations.flat_map { |operation| operation.targets.keys }).index_by { |user| user.id.to_s }
      end
    end

    private

    def load_audit_logs
      @audit_page = [ params[:audit_page].to_i, 1 ].max
      logs = AuditLog.includes(:actor).order(id: :desc)
      logs = logs.where.not("action LIKE ?", "trust.risk.%") unless current_user.permission?("trust.risk")
      logs = logs.where.not("action LIKE ?", "points.%") unless current_user.permission?("points.read")
      logs = logs.where.not("action LIKE ?", "financial.%") unless current_user.permission?("financial.read")
      logs = logs.where.not("action LIKE ?", "organization.legal.%") unless current_user.permission?("organizations.legal")
      logs = logs.where(action: params[:audit_event]) if params[:audit_event].present?
      @audit_total = logs.count
      @audit_logs = logs.limit(20).offset((@audit_page - 1) * 20)
    end
  end
end
