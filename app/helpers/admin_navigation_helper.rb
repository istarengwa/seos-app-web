module AdminNavigationHelper
  def admin_navigation_groups
    groups = [
      { label: "Essentiel", links: [
        nav_if("Membres", admin_users_path, %w[users.read], "admin/users"),
        workbench_nav("Annonces", "annonces"),
        (nav_if(admin_community_label, admin_community_index_path, %w[community.read community.manage community.rules], "admin/community") if current_user.super_admin? || %w[quests chains testimonials highlights].any? { |feature| AppFeatures.enabled?(feature) }),
        (nav_if("Preuves de récompense", admin_points_path, %w[points.rewards], "admin/points") if current_user.super_admin? || AppFeatures.enabled?("quests"))
      ].compact },
      { label: "Communauté", links: [
        (nav_if("Associations & missions", admin_network_index_path, %w[organizations.read organizations.manage organizations.legal missions.manage], "admin/network") if current_user.super_admin? || AppFeatures.enabled?("associations")),
        workbench_nav("Échanges", "echanges"),
        workbench_nav("Signalements", "signalements"),
        nav_if("Confiance", admin_trust_index_path, %w[trust.read trust.manage trust.risk], "admin/trust")
      ].compact },
      { label: "Outils", links: [
        (admin_nav_item("Fonctionnalités", admin_features_path, controller_path == "admin/features") if current_user.super_admin?),
        workbench_nav("Catégories", "categories"),
        (admin_nav_item("Éditeur visuel", admin_site_index_path, controller_path.in?(%w[admin/site admin/visual_studio])) if current_user.super_admin?),
        (admin_nav_item("Page partenaires", edit_admin_partnership_page_path, controller_path == "admin/partnership_pages") if current_user.super_admin?),
        (admin_nav_item("Administrateurs", super_admin_administrators_path, controller_path == "super_admin/administrators") if current_user.super_admin?)
      ].compact }
    ]
    groups.select { |group| group[:links].any? }
  end

  def admin_nav_item(label, path, active) = { label: label, path: path, active: active }

  def admin_community_label
    return "Quêtes & chaînes" if current_user.super_admin? || (AppFeatures.enabled?("quests") && AppFeatures.enabled?("chains"))
    return "Quêtes" if AppFeatures.enabled?("quests")
    AppFeatures.enabled?("chains") ? "Chaînes d’entraide" : "Engagement"
  end

  private

  def nav_if(label, path, permissions, controller)
    admin_nav_item(label, path, controller_path == controller) if permissions.any? { |permission| current_user.permission?(permission) }
  end

  def workbench_nav(label, kind)
    permission = Admin::WorkbenchController::RESOURCES.fetch(kind)[1]
    admin_nav_item(label, admin_workbench_index_path(kind: kind), controller_path == "admin/workbench" && params[:kind] == kind) if current_user.permission?(permission)
  end
end
