class AddSwitchMetadataToFeatureFlags < ActiveRecord::Migration[8.1]
  def up
    add_column :feature_flags, :disabled_at, :datetime
    remove_check_constraint :feature_flags, name: "feature_flags_key_values"
    keys = %w[public_map_enabled voyage_enabled associations_enabled quests_enabled chains_enabled referrals_enabled testimonials_enabled highlights_enabled journal_enabled google_login_enabled]
    add_check_constraint :feature_flags, "key IN (#{keys.map { |key| connection.quote(key) }.join(',')})", name: "feature_flags_key_values"
    execute "UPDATE feature_flags SET disabled_at = updated_at WHERE enabled = #{connection.quote(false)}"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Conserver les réglages des modules : ne pas supprimer leurs clés."
  end
end
