class PointAccount < ApplicationRecord
  include ImmutableInputs
  immutable_inputs :user_id, :kind
  belongs_to :user, optional: true
  has_many :point_entries, dependent: :restrict_with_exception
  validates :balance, numericality: { only_integer: true, in: -9_000_000_000_000_000..9_000_000_000_000_000 }
  validate :balance_follows_entries
  def self.for!(user) = create_or_find_by!(user: user, kind: "user")
  def self.system! = create_or_find_by!(kind: "system", user: nil)

  private

  def balance_follows_entries
    expected = persisted? ? point_entries.sum(:amount) : 0
    errors.add(:balance, "doit correspondre aux écritures du portefeuille") unless balance == expected
  end
end
