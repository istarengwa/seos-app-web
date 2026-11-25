class DeviseCreateUsers < ActiveRecord::Migration[8.1]
  def change
    # User creation now runs at the start of CreateDiscoveryAndExchanges.
    # Keep this migration version so existing installations retain their history.
  end
end
