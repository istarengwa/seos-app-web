class PointEntry < ApplicationRecord
  belongs_to :point_account
  belongs_to :point_operation
  validates :amount, numericality: { only_integer: true, other_than: 0, in: -999_999..999_999 }
  validate :valid_ledger_entry, on: :create
  after_create :apply_balance
  def readonly? = persisted?

  private

  def valid_ledger_entry
    return unless point_account && point_operation
    point_account.lock!
    errors.add(:point_operation, "est déjà validée") unless point_operation.reload.status == "pending"
    errors.add(:balance_after, "ne correspond pas au solde et au montant") unless amount && balance_after == point_account.balance + amount
  end

  def apply_balance
    point_account.update!(balance: balance_after)
  end
end
