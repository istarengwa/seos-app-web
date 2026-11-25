class MoveDatabaseGuardsToRails < ActiveRecord::Migration[8.1]
  # listings precedes organizations; add this foreign key after both tables exist.

  def up
    remove_legacy_triggers
    unless foreign_key_exists?(:listings, :organizations)
      add_foreign_key :listings, :organizations
    end
    add_column :studio_versions, :system_generated, :boolean, null: false, default: false
    change_column_null :studio_versions, :author_id, true
    create_table :seed_runs do |t|
      t.string :name, null: false
      t.datetime :completed_at
      t.timestamps
    end
    add_index :seed_runs, :name, unique: true
    # Upgrading an existing installation must never initialize or replace its homepage.
    if select_value("SELECT COUNT(*) FROM users").to_i.positive? || select_value("SELECT COUNT(*) FROM studio_versions").to_i.positive?
      execute "INSERT INTO seed_runs (name, completed_at, created_at, updated_at) VALUES ('production_home', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "The SQL guards were replaced by Rails rules; restore a backup to return to that implementation."
  end

  private

  def remove_legacy_triggers
    if connection.adapter_name == "SQLite"
      select_values("SELECT name FROM sqlite_master WHERE type = 'trigger'").each do |name|
        execute "DROP TRIGGER #{connection.quote_column_name(name)}"
      end
    elsif connection.adapter_name == "PostgreSQL"
      select_all(<<~SQL).each do |trigger|
        SELECT t.tgname, c.relname FROM pg_trigger t
        JOIN pg_class c ON c.oid = t.tgrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE NOT t.tgisinternal AND n.nspname = current_schema()
      SQL
        execute "DROP TRIGGER #{connection.quote_column_name(trigger['tgname'])} ON #{connection.quote_table_name(trigger['relname'])}"
        execute "DROP FUNCTION IF EXISTS #{connection.quote_column_name("#{trigger['tgname']}_fn")}()"
      end
    end
  end
end
