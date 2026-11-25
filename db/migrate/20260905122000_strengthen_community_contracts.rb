class StrengthenCommunityContracts < ActiveRecord::Migration[8.1]
  def change
    add_column :financial_contributions, :refund_requested_at, :datetime
  end
end
