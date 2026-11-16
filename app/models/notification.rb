class Notification < ApplicationRecord
  CATEGORIES = {
    "messages" => "Messagerie", "quests" => "Mes quêtes", "wallet" => "Mon portefeuille",
    "favorites" => "Mes favoris", "profile" => "Profil et paramètres", "listings" => "Mes annonces",
    "reviews" => "Avis reçus", "testimonials" => "Mes témoignages", "chains" => "Mes chaînes",
    "trust" => "Confiance et parrainage", "organizations" => "Mes organisations",
    "missions" => "Mes candidatures", "privacy" => "Mes données et mes droits",
    "security" => "Sécurité du compte", "general" => "Autres notifications"
  }.freeze
  PREFIX_CATEGORIES = { "message" => "messages", "exchange" => "messages", "review" => "reviews",
    "achievement" => "quests", "top" => "quests", "points" => "wallet", "testimonial" => "testimonials",
    "referral" => "trust", "trust" => "trust", "chain" => "chains", "mission" => "missions",
    "restriction" => "listings" }.freeze
  scope :unread, -> { where(read_at: nil) }
  scope :feature_visible, -> {
    scope = all
    values = AppFeatures.flags
    AppFeatures::NOTICE_PREFIXES.each do |prefix, feature|
      scope = scope.where.not("event_key LIKE ?", "#{prefix}:%") unless AppFeatures.enabled?(feature, values)
    end
    scope
  }
  validates :category, inclusion: { in: CATEGORIES.keys }
  belongs_to :user
  belongs_to :service_request, optional: true
  after_create_commit -> { NotificationEmailJob.perform_later(self) }
  validates :title, :event_key, presence: true
  def self.notify!(user:, key:, title:, request: nil, category: nil)
    feature = AppFeatures.notice_feature(key)
    return if feature && !AppFeatures.enabled?(feature)
    create_or_find_by!(user: user, event_key: key) do |notice|
      notice.category = category || PREFIX_CATEGORIES.fetch(key.split(":").first, "general")
      notice.title = title
      notice.service_request = request
    end
  end
end
