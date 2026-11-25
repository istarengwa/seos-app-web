class PointRewardClaim < ApplicationRecord
  include ImmutableInputs
  immutable_inputs :user_id, :point_rule_version_id, :kind, :period_key, :evidence, :amount, :level
  belongs_to :user
  belongs_to :point_rule_version
  belongs_to :reviewed_by, class_name: "User", optional: true
  belongs_to :point_operation, optional: true
  encrypts :evidence, :decision
  validates :evidence, presence: true, length: { maximum: 3000 }
  validates :kind, inclusion: { in: %w[written video share chain] }
  validates :status, inclusion: { in: %w[pending approved rejected] }
  def readonly? = persisted? && status_in_database != "pending"
end
