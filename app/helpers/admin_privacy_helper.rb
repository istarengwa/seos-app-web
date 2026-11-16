module AdminPrivacyHelper
  RETENTION_LABELS = {
    "exports" => "Fichiers d’export des membres", "sessions" => "Sessions de connexion terminées",
    "notifications" => "Notifications", "contacts" => "Demandes de contact résolues",
    "invitations" => "Invitations expirées", "cookie_preferences" => "Choix de cookies expirés"
  }.freeze

  def retention_label(purpose) = RETENTION_LABELS.fetch(purpose)
end
