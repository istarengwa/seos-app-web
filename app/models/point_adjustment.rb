class PointAdjustment < ApplicationRecord
  include ImmutableInputs
  immutable_inputs :user_id, :proposed_by_id, :amount, :balance_before, :reason, :expires_at
  belongs_to :user
  belongs_to :proposed_by, class_name: "User"
  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :point_operation, optional: true
  encrypts :reason
  validates :amount, numericality: { only_integer: true, other_than: 0, in: -999_999..999_999 }
  validates :reason, presence: true, length: { maximum: 500 }
  def readonly? = persisted? && point_operation_id_in_database.present?
end
