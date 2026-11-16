class UserAchievement < ApplicationRecord
  include ImmutableInputs
  immutable_inputs :user_id, :achievement_id, :point_rule_version_id, :points, :period_key, :evidence
  belongs_to :user
  belongs_to :achievement
  belongs_to :point_rule_version
  belongs_to :point_operation, optional: true
  belongs_to :reviewed_by, class_name: "User", optional: true
  encrypts :evidence, :decision
  has_one_attached :proof
  validates :evidence, presence: true, length: { maximum: 3000 }
  validates :status, inclusion: { in: %w[submitted approved rejected] }
  def readonly? = persisted? && status_in_database == "approved"
end
