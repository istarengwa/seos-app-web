class NormalizePortableConstraints < ActiveRecord::Migration[8.1]
  def up
    change_column :users, :email, :string, null: false, collation: nil
    remove_check_constraint :point_accounts, name: "point_balance_integer"
    add_check_constraint :point_accounts, "balance BETWEEN -9000000000000000 AND 9000000000000000", name: "point_balance_integer"
    remove_check_constraint :point_entries, name: "point_entry_integer"
    add_check_constraint :point_entries, "amount != 0 AND amount BETWEEN -999999 AND 999999", name: "point_entry_integer"
    remove_check_constraint :chain_services, name: "no_self_chain_validation"
    add_check_constraint :chain_services, "beneficiary_id IS NULL OR provider_id != beneficiary_id", name: "no_self_chain_validation"
    remove_check_constraint :review_ratings, name: "rating_or_na"
    add_check_constraint :review_ratings, "(not_applicable = TRUE AND rating IS NULL) OR (not_applicable = FALSE AND rating BETWEEN 1 AND 5 AND rating IS NOT NULL)", name: "rating_or_na"
    remove_index :referrals, name: "one_primary_referrer"
    add_index :referrals, :referred_user_id, unique: true, where: "primary_referrer = TRUE", name: "one_primary_referrer"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "The normalized constraints work with both PostgreSQL and SQLite."
  end
end
