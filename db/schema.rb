# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_16_120000) do
  create_table "achievements", force: :cascade do |t|
    t.string "accent", default: "ocean", null: false
    t.boolean "active", default: true, null: false
    t.boolean "animated", default: true, null: false
    t.boolean "builtin", default: false, null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.string "event_name", null: false
    t.string "icon", default: "spark", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "recurrence", default: "once", null: false
    t.string "reward_key", null: false
    t.string "slug", null: false
    t.integer "target_count", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_achievements_on_slug", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_permission_grants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.datetime "granted_at", null: false
    t.integer "granted_by_id", null: false
    t.string "permission", null: false
    t.string "reason", null: false
    t.datetime "revoked_at"
    t.integer "revoked_by_id"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["granted_by_id"], name: "index_admin_permission_grants_on_granted_by_id"
    t.index ["revoked_by_id"], name: "index_admin_permission_grants_on_revoked_by_id"
    t.index ["user_id", "permission"], name: "unique_unrevoked_permission", unique: true, where: "revoked_at IS NULL"
    t.index ["user_id"], name: "index_admin_permission_grants_on_user_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.integer "actor_id", null: false
    t.datetime "created_at", null: false
    t.json "metadata", default: {}, null: false
    t.string "reason", null: false
    t.integer "target_id", null: false
    t.string "target_type", null: false
    t.index ["actor_id"], name: "index_audit_logs_on_actor_id"
    t.index ["target_type", "target_id"], name: "index_audit_logs_on_target"
  end

  create_table "bulk_operations", force: :cascade do |t|
    t.integer "actor_id", null: false
    t.integer "approved_by_id"
    t.datetime "created_at", null: false
    t.datetime "executed_at"
    t.datetime "expires_at", null: false
    t.text "reason", null: false
    t.json "targets", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_bulk_operations_on_actor_id"
    t.index ["approved_by_id"], name: "index_bulk_operations_on_approved_by_id"
  end

  create_table "categories", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "name", null: false
    t.integer "parent_id"
    t.integer "position", default: 0, null: false
    t.boolean "sensitive", default: false, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_categories_on_deleted_at"
    t.index ["parent_id"], name: "index_categories_on_parent_id"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "chain_rewards", force: :cascade do |t|
    t.integer "chain_rule_version_id", null: false
    t.integer "chain_service_id", null: false
    t.datetime "created_at", null: false
    t.integer "point_operation_id"
    t.integer "points", null: false
    t.integer "recipient_id", null: false
    t.integer "reward_rank", null: false
    t.index ["chain_rule_version_id"], name: "index_chain_rewards_on_chain_rule_version_id"
    t.index ["chain_service_id", "recipient_id"], name: "index_chain_rewards_on_chain_service_id_and_recipient_id", unique: true
    t.index ["chain_service_id"], name: "index_chain_rewards_on_chain_service_id"
    t.index ["point_operation_id"], name: "index_chain_rewards_on_point_operation_id"
    t.index ["recipient_id"], name: "index_chain_rewards_on_recipient_id"
    t.check_constraint "points >= 0", name: "nonnegative_chain_reward"
  end

  create_table "chain_rule_versions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "created_by_id"
    t.datetime "effective_at", null: false
    t.string "length_mode", default: "unlimited", null: false
    t.integer "max_links"
    t.integer "max_points_per_link", default: 30, null: false
    t.integer "max_points_per_member", default: 100, null: false
    t.string "name", null: false
    t.integer "points_per_validation", default: 10, null: false
    t.datetime "published_at"
    t.string "reward_scope", default: "provider_only", null: false
    t.integer "rewarded_previous_links", default: 1, null: false
    t.json "simulation", default: {}, null: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_chain_rule_versions_on_created_by_id"
    t.index ["effective_at"], name: "one_chain_rule_effective_date", unique: true, where: "status = 'published'"
  end

  create_table "chain_services", force: :cascade do |t|
    t.integer "beneficiary_id"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.integer "help_chain_id", null: false
    t.datetime "invitation_expires_at", null: false
    t.string "invitation_token_digest", null: false
    t.integer "position", null: false
    t.integer "provider_id", null: false
    t.string "status", default: "invited", null: false
    t.datetime "updated_at", null: false
    t.index ["beneficiary_id"], name: "index_chain_services_on_beneficiary_id"
    t.index ["help_chain_id", "beneficiary_id"], name: "unique_chain_beneficiary", unique: true, where: "status = 'confirmed'"
    t.index ["help_chain_id", "position"], name: "index_chain_services_on_help_chain_id_and_position", unique: true
    t.index ["help_chain_id"], name: "index_chain_services_on_help_chain_id"
    t.index ["help_chain_id"], name: "one_chain_invitation", unique: true, where: "status = 'invited'"
    t.index ["invitation_token_digest"], name: "index_chain_services_on_invitation_token_digest", unique: true
    t.index ["provider_id"], name: "index_chain_services_on_provider_id"
    t.check_constraint "beneficiary_id IS NULL OR provider_id != beneficiary_id", name: "no_self_chain_validation"
  end

  create_table "comments", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.integer "listing_id", null: false
    t.datetime "removed_at"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["listing_id"], name: "index_comments_on_listing_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "community_policy_versions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "created_by_id"
    t.integer "top_max_days", default: 30, null: false
    t.integer "urgent_days", default: 7, null: false
    t.index ["created_by_id"], name: "index_community_policy_versions_on_created_by_id"
    t.check_constraint "urgent_days BETWEEN 1 AND 30 AND top_max_days BETWEEN 1 AND 90", name: "community_policy_bounds"
  end

  create_table "contact_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "email", null: false
    t.text "message", null: false
    t.datetime "resolved_at"
    t.string "status", default: "open", null: false
    t.string "subject", null: false
    t.datetime "updated_at", null: false
  end

  create_table "content_versions", force: :cascade do |t|
    t.datetime "archived_at"
    t.integer "author_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.json "decorations", default: [], null: false
    t.string "kind", null: false
    t.datetime "published_at"
    t.string "slug", null: false
    t.string "summary"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "version", null: false
    t.index ["author_id"], name: "index_content_versions_on_author_id"
    t.index ["kind", "slug", "version"], name: "index_content_versions_on_kind_and_slug_and_version", unique: true
    t.check_constraint "kind IN ('page','article','legal')", name: "content_versions_kind_values"
  end

  create_table "cookie_consents", force: :cascade do |t|
    t.boolean "analytics", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.boolean "external_media", default: false, null: false
    t.datetime "updated_at", null: false
    t.string "version", null: false
    t.string "visitor_digest", null: false
    t.index ["visitor_digest", "created_at"], name: "index_cookie_consents_on_visitor_digest_and_created_at"
  end

  create_table "crawler_policies", force: :cascade do |t|
    t.integer "author_id", null: false
    t.datetime "created_at", null: false
    t.boolean "search_enabled", default: true, null: false
    t.boolean "training_enabled", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_crawler_policies_on_author_id"
  end

  create_table "data_requests", force: :cascade do |t|
    t.integer "approved_by_id"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.text "details"
    t.datetime "export_expires_at"
    t.string "kind", null: false
    t.json "preview", default: {}, null: false
    t.text "response"
    t.datetime "response_due_at", null: false
    t.integer "reviewed_by_id"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.datetime "verified_at"
    t.index ["approved_by_id"], name: "index_data_requests_on_approved_by_id"
    t.index ["reviewed_by_id"], name: "index_data_requests_on_reviewed_by_id"
    t.index ["user_id", "kind"], name: "unique_open_data_request", unique: true, where: "status IN ('pending','reviewed','executing')"
    t.index ["user_id"], name: "index_data_requests_on_user_id"
  end

  create_table "favorites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "listing_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["listing_id"], name: "index_favorites_on_listing_id"
    t.index ["user_id", "listing_id"], name: "index_favorites_on_user_id_and_listing_id", unique: true
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "feature_flags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "disabled_at"
    t.boolean "enabled", default: true, null: false
    t.string "key", null: false
    t.integer "lock_version", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_feature_flags_on_key", unique: true
    t.check_constraint "key IN ('public_map_enabled','voyage_enabled','associations_enabled','quests_enabled','chains_enabled','referrals_enabled','testimonials_enabled','highlights_enabled','journal_enabled','google_login_enabled')", name: "feature_flags_key_values"
  end

  create_table "google_identities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["uid"], name: "index_google_identities_on_uid", unique: true
    t.index ["user_id"], name: "index_google_identities_on_user_id"
    t.index ["user_id"], name: "one_google_identity_per_user", unique: true
  end

  create_table "help_chains", force: :cascade do |t|
    t.integer "chain_rule_version_id", null: false
    t.datetime "created_at", null: false
    t.integer "creator_id", null: false
    t.boolean "featured_on_home", default: false, null: false
    t.string "name", null: false
    t.integer "point_rule_version_id", null: false
    t.string "slug", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["chain_rule_version_id"], name: "index_help_chains_on_chain_rule_version_id"
    t.index ["creator_id"], name: "index_help_chains_on_creator_id"
    t.index ["point_rule_version_id"], name: "index_help_chains_on_point_rule_version_id"
    t.index ["slug"], name: "index_help_chains_on_slug", unique: true
  end

  create_table "listings", force: :cascade do |t|
    t.text "address_line"
    t.text "availability"
    t.integer "category_id"
    t.string "city"
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "estimated_points"
    t.string "exchange_mode", default: "gift", null: false
    t.datetime "expires_at"
    t.string "intent", default: "offer", null: false
    t.float "latitude"
    t.integer "lock_version", default: 0, null: false
    t.float "longitude"
    t.boolean "moderation_hold", default: false, null: false
    t.integer "organization_id"
    t.string "priority", default: "standard", null: false
    t.datetime "published_at"
    t.datetime "removed_at"
    t.string "service_location_mode", default: "in_person", null: false
    t.string "slug", null: false
    t.string "status", default: "draft", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.datetime "urgent_until"
    t.integer "user_id", null: false
    t.integer "wizard_step", default: 1, null: false
    t.index ["category_id"], name: "index_listings_on_category_id"
    t.index ["organization_id"], name: "index_listings_on_organization_id"
    t.index ["slug"], name: "index_listings_on_slug", unique: true
    t.index ["status", "expires_at"], name: "index_listings_on_status_and_expires_at"
    t.index ["status", "published_at", "id"], name: "index_listings_on_status_and_published_at_and_id"
    t.index ["user_id"], name: "index_listings_on_user_id"
    t.check_constraint "(exchange_mode = 'points' AND (estimated_points IS NULL OR estimated_points > 0)) OR (exchange_mode != 'points' AND estimated_points IS NULL)", name: "listing_points_mode"
    t.check_constraint "exchange_mode IN ('gift','barter','points')", name: "listings_exchange_mode_values"
    t.check_constraint "intent IN ('offer','request')", name: "listings_intent_values"
    t.check_constraint "priority IN ('standard','urgent')", name: "listings_priority_values"
    t.check_constraint "service_location_mode IN ('in_person','remote','hybrid')", name: "listings_service_location_mode_values"
    t.check_constraint "status IN ('draft','pending_review','published','paused','closed','removed')", name: "listings_status_values"
  end

  create_table "login_blocks", force: :cascade do |t|
    t.integer "actor_id", null: false
    t.datetime "created_at", null: false
    t.string "email_digest", null: false
    t.datetime "expires_at", null: false
    t.text "reason", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_login_blocks_on_actor_id"
    t.index ["email_digest"], name: "index_login_blocks_on_email_digest"
  end

  create_table "login_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.datetime "last_seen_at", null: false
    t.datetime "reauthenticated_at"
    t.datetime "revoked_at"
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent_summary", null: false
    t.integer "user_id", null: false
    t.index ["expires_at"], name: "index_login_sessions_on_expires_at"
    t.index ["token_digest"], name: "index_login_sessions_on_token_digest", unique: true
    t.index ["user_id"], name: "index_login_sessions_on_user_id"
  end

  create_table "mail_deliveries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "message_id", null: false
    t.string "provider_id"
    t.string "status", default: "uncertain", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_mail_deliveries_on_message_id", unique: true
  end

  create_table "messages", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.string "delivery_key", null: false
    t.datetime "read_at"
    t.datetime "removed_at"
    t.integer "sender_id", null: false
    t.integer "service_request_id", null: false
    t.datetime "updated_at", null: false
    t.index ["sender_id", "delivery_key"], name: "index_messages_on_sender_id_and_delivery_key", unique: true
    t.index ["sender_id"], name: "index_messages_on_sender_id"
    t.index ["service_request_id"], name: "index_messages_on_service_request_id"
  end

  create_table "mission_applications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "decided_at"
    t.date "ends_on", null: false
    t.text "message", null: false
    t.date "starts_on", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "volunteer_mission_id", null: false
    t.index ["user_id"], name: "index_mission_applications_on_user_id"
    t.index ["volunteer_mission_id", "user_id"], name: "index_mission_applications_on_volunteer_mission_id_and_user_id", unique: true
    t.index ["volunteer_mission_id"], name: "index_mission_applications_on_volunteer_mission_id"
  end

  create_table "mission_messages", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.string "delivery_key", null: false
    t.integer "mission_application_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["mission_application_id", "user_id", "delivery_key"], name: "unique_mission_message", unique: true
    t.index ["mission_application_id"], name: "index_mission_messages_on_mission_application_id"
    t.index ["user_id"], name: "index_mission_messages_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "category", default: "general", null: false
    t.datetime "created_at", null: false
    t.datetime "emailed_at"
    t.string "event_key", null: false
    t.datetime "read_at"
    t.integer "service_request_id"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["service_request_id"], name: "index_notifications_on_service_request_id"
    t.index ["user_id", "event_key"], name: "index_notifications_on_user_id_and_event_key", unique: true
    t.index ["user_id", "read_at", "category"], name: "notification_unread_categories"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "organization_invitations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.integer "accepted_by_id"
    t.datetime "created_at", null: false
    t.text "email", null: false
    t.datetime "expires_at", null: false
    t.integer "invited_by_id", null: false
    t.integer "organization_id", null: false
    t.datetime "revoked_at"
    t.string "role", null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["accepted_by_id"], name: "index_organization_invitations_on_accepted_by_id"
    t.index ["invited_by_id"], name: "index_organization_invitations_on_invited_by_id"
    t.index ["organization_id"], name: "index_organization_invitations_on_organization_id"
    t.index ["token_digest"], name: "index_organization_invitations_on_token_digest", unique: true
  end

  create_table "organization_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "organization_id", null: false
    t.string "role", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["organization_id", "user_id"], name: "index_organization_memberships_on_organization_id_and_user_id", unique: true
    t.index ["organization_id"], name: "index_organization_memberships_on_organization_id"
    t.index ["user_id"], name: "index_organization_memberships_on_user_id"
    t.check_constraint "role IN ('owner', 'manager', 'editor')", name: "memberships_role"
    t.check_constraint "status IN ('active', 'revoked')", name: "memberships_status"
  end

  create_table "organizations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "kind", null: false
    t.text "legal_email"
    t.text "legal_name"
    t.integer "lock_version", default: 0, null: false
    t.string "name", null: false
    t.string "public_location"
    t.datetime "published_at"
    t.text "registration_number"
    t.string "request_kind"
    t.string "slug", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.datetime "verified_at"
    t.integer "verified_by_id"
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
    t.index ["verified_by_id"], name: "index_organizations_on_verified_by_id"
    t.check_constraint "kind IN ('association', 'company', 'micro_company', 'institution', 'collective')", name: "organizations_kind"
    t.check_constraint "request_kind IS NULL OR request_kind = 'community_mission'", name: "organizations_request_kind"
    t.check_constraint "status IN ('pending', 'verified', 'rejected', 'suspended')", name: "organizations_status"
  end

  create_table "partner_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "partnership_page_id", null: false
    t.integer "position", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "website_url", null: false
    t.index ["partnership_page_id", "position"], name: "index_partner_entries_on_partnership_page_id_and_position"
    t.index ["partnership_page_id"], name: "index_partner_entries_on_partnership_page_id"
  end

  create_table "partnership_pages", force: :cascade do |t|
    t.text "body"
    t.string "contact_label"
    t.string "contact_url"
    t.datetime "created_at", null: false
    t.text "introduction"
    t.integer "lock_version", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "updated_by_id"
    t.index ["updated_by_id"], name: "index_partnership_pages_on_updated_by_id"
  end

  create_table "point_accounts", force: :cascade do |t|
    t.bigint "balance", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "kind", default: "user", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["kind"], name: "one_point_system_account", unique: true, where: "kind = 'system'"
    t.index ["user_id"], name: "index_point_accounts_on_user_id", unique: true
    t.check_constraint "(kind = 'user' AND user_id IS NOT NULL AND balance >= 0) OR (kind = 'system' AND user_id IS NULL)", name: "point_account_owner_and_balance"
    t.check_constraint "balance BETWEEN -9000000000000000 AND 9000000000000000", name: "point_balance_integer"
  end

  create_table "point_adjustments", force: :cascade do |t|
    t.integer "amount", null: false
    t.integer "approved_by_id"
    t.bigint "balance_before", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.integer "point_operation_id"
    t.integer "proposed_by_id", null: false
    t.text "reason", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["approved_by_id"], name: "index_point_adjustments_on_approved_by_id"
    t.index ["point_operation_id"], name: "index_point_adjustments_on_point_operation_id"
    t.index ["proposed_by_id"], name: "index_point_adjustments_on_proposed_by_id"
    t.index ["user_id"], name: "index_point_adjustments_on_user_id"
  end

  create_table "point_cycle_progresses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "cycle_number", null: false
    t.json "operation_ids", default: [], null: false
    t.integer "point_operation_id"
    t.integer "point_rule_version_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["point_operation_id"], name: "index_point_cycle_progresses_on_point_operation_id"
    t.index ["point_rule_version_id"], name: "index_point_cycle_progresses_on_point_rule_version_id"
    t.index ["user_id", "cycle_number"], name: "index_point_cycle_progresses_on_user_id_and_cycle_number", unique: true
    t.index ["user_id"], name: "index_point_cycle_progresses_on_user_id"
  end

  create_table "point_entries", force: :cascade do |t|
    t.bigint "amount", null: false
    t.bigint "balance_after", null: false
    t.datetime "created_at", null: false
    t.integer "point_account_id", null: false
    t.integer "point_operation_id", null: false
    t.index ["point_account_id"], name: "index_point_entries_on_point_account_id"
    t.index ["point_operation_id", "point_account_id"], name: "one_entry_per_point_account", unique: true
    t.index ["point_operation_id"], name: "index_point_entries_on_point_operation_id"
    t.check_constraint "amount != 0 AND amount BETWEEN -999999 AND 999999", name: "point_entry_integer"
  end

  create_table "point_operations", force: :cascade do |t|
    t.datetime "committed_at"
    t.datetime "created_at", null: false
    t.string "idempotency_key", null: false
    t.integer "initiator_id"
    t.string "kind", null: false
    t.integer "point_rule_version_id"
    t.text "reason", null: false
    t.integer "reversed_operation_id"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.string "status", default: "pending", null: false
    t.index ["idempotency_key"], name: "index_point_operations_on_idempotency_key", unique: true
    t.index ["initiator_id"], name: "index_point_operations_on_initiator_id"
    t.index ["point_rule_version_id"], name: "index_point_operations_on_point_rule_version_id"
    t.index ["reversed_operation_id"], name: "index_point_operations_on_reversed_operation_id", unique: true
    t.index ["source_type", "source_id"], name: "index_point_operations_on_source"
  end

  create_table "point_reward_claims", force: :cascade do |t|
    t.integer "amount", null: false
    t.datetime "created_at", null: false
    t.text "decision"
    t.text "evidence", null: false
    t.string "kind", null: false
    t.string "level", default: "bronze", null: false
    t.string "period_key", null: false
    t.integer "point_operation_id"
    t.integer "point_rule_version_id", null: false
    t.integer "reviewed_by_id"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["point_operation_id"], name: "index_point_reward_claims_on_point_operation_id"
    t.index ["point_rule_version_id"], name: "index_point_reward_claims_on_point_rule_version_id"
    t.index ["reviewed_by_id"], name: "index_point_reward_claims_on_reviewed_by_id"
    t.index ["user_id", "kind", "period_key"], name: "unique_point_reward_claim", unique: true
    t.index ["user_id"], name: "index_point_reward_claims_on_user_id"
  end

  create_table "point_rule_versions", force: :cascade do |t|
    t.json "configuration", default: {}, null: false
    t.datetime "created_at", null: false
    t.integer "created_by_id"
    t.datetime "effective_at", null: false
    t.string "family", null: false
    t.string "name", null: false
    t.datetime "published_at"
    t.json "simulation", default: {}, null: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_point_rule_versions_on_created_by_id"
    t.index ["family", "effective_at"], name: "unique_point_rule_effective_date", unique: true, where: "status = 'published'"
  end

  create_table "privacy_runs", force: :cascade do |t|
    t.integer "actor_id", null: false
    t.integer "approved_by_id"
    t.datetime "created_at", null: false
    t.datetime "executed_at"
    t.datetime "expires_at", null: false
    t.text "reason", null: false
    t.integer "retention_policy_version_id", null: false
    t.string "status", default: "preview", null: false
    t.json "targets", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_privacy_runs_on_actor_id"
    t.index ["approved_by_id"], name: "index_privacy_runs_on_approved_by_id"
    t.index ["retention_policy_version_id"], name: "index_privacy_runs_on_retention_policy_version_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.text "address_line"
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "display_name", null: false
    t.string "languages"
    t.text "phone"
    t.string "phone_sharing_policy", default: "per_exchange", null: false
    t.string "public_city"
    t.string "public_slug", null: false
    t.string "skills"
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["public_slug"], name: "index_profiles_on_public_slug", unique: true
    t.index ["user_id"], name: "index_profiles_on_user_id", unique: true
    t.check_constraint "phone_sharing_policy IN ('per_exchange','nobody')", name: "profiles_phone_sharing_policy_values"
    t.check_constraint "status IN ('draft','published','restricted','anonymized')", name: "profiles_status_values"
  end

  create_table "provider_erasure_tasks", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "data_request_id", null: false
    t.string "provider", null: false
    t.text "response"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["data_request_id", "provider"], name: "index_provider_erasure_tasks_on_data_request_id_and_provider", unique: true
    t.index ["data_request_id"], name: "index_provider_erasure_tasks_on_data_request_id"
  end

  create_table "referral_codes", force: :cascade do |t|
    t.datetime "claimed_at"
    t.string "code_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.integer "owner_id", null: false
    t.datetime "updated_at", null: false
    t.index ["code_digest"], name: "index_referral_codes_on_code_digest", unique: true
    t.index ["owner_id"], name: "index_referral_codes_on_owner_id"
  end

  create_table "referral_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "owner_id", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_referral_links_on_owner_id", unique: true
    t.index ["token"], name: "index_referral_links_on_token", unique: true
  end

  create_table "referrals", force: :cascade do |t|
    t.datetime "claimed_at", null: false
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "invalidated_at"
    t.text "invalidation_reason"
    t.datetime "objection_deadline_at", null: false
    t.integer "position", null: false
    t.boolean "primary_referrer", default: false, null: false
    t.datetime "qualified_at"
    t.integer "referral_code_id"
    t.integer "referral_link_id"
    t.integer "referred_user_id", null: false
    t.integer "referrer_id", null: false
    t.string "status", default: "provisional", null: false
    t.datetime "updated_at", null: false
    t.index ["referral_code_id"], name: "index_referrals_on_referral_code_id", unique: true
    t.index ["referral_link_id"], name: "index_referrals_on_referral_link_id"
    t.index ["referred_user_id", "position"], name: "index_referrals_on_referred_user_id_and_position", unique: true
    t.index ["referred_user_id"], name: "index_referrals_on_referred_user_id"
    t.index ["referred_user_id"], name: "one_invitation_per_member", unique: true, where: "referral_link_id IS NOT NULL"
    t.index ["referred_user_id"], name: "one_primary_referrer", unique: true, where: "primary_referrer = TRUE"
    t.index ["referrer_id", "referred_user_id"], name: "index_referrals_on_referrer_id_and_referred_user_id", unique: true
    t.index ["referrer_id"], name: "index_referrals_on_referrer_id"
    t.check_constraint "position BETWEEN 1 AND 10", name: "referral_position_range"
    t.check_constraint "referrer_id != referred_user_id", name: "no_self_referral"
    t.check_constraint "status IN ('provisional', 'confirmed', 'objected', 'invalidated')", name: "referral_status"
  end

  create_table "reports", force: :cascade do |t|
    t.integer "assigned_to_id"
    t.datetime "created_at", null: false
    t.text "details"
    t.datetime "due_at", null: false
    t.string "reason", null: false
    t.integer "reportable_id", null: false
    t.string "reportable_type", null: false
    t.integer "reporter_id", null: false
    t.text "resolution"
    t.datetime "resolved_at"
    t.string "status", default: "open", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id"], name: "index_reports_on_assigned_to_id"
    t.index ["reportable_type", "reportable_id"], name: "index_reports_on_reportable"
    t.index ["reporter_id"], name: "index_reports_on_reporter_id"
    t.check_constraint "reportable_type IN ('Listing','Profile','Message','Comment','Review','ServiceRequest')", name: "reports_reportable_type_values"
    t.check_constraint "status IN ('open','investigating','resolved')", name: "reports_status_values"
  end

  create_table "request_events", force: :cascade do |t|
    t.integer "actor_id", null: false
    t.datetime "created_at", null: false
    t.text "details"
    t.string "kind", null: false
    t.integer "service_request_id", null: false
    t.index ["actor_id"], name: "index_request_events_on_actor_id"
    t.index ["service_request_id"], name: "index_request_events_on_service_request_id"
  end

  create_table "retention_policy_versions", force: :cascade do |t|
    t.integer "approved_by_id"
    t.datetime "created_at", null: false
    t.integer "created_by_id"
    t.datetime "effective_at"
    t.datetime "expires_at"
    t.datetime "legal_reviewed_at"
    t.string "name", null: false
    t.datetime "published_at"
    t.json "rules", default: {}, null: false
    t.json "simulation", default: {}, null: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.index ["approved_by_id"], name: "index_retention_policy_versions_on_approved_by_id"
    t.index ["created_by_id"], name: "index_retention_policy_versions_on_created_by_id"
  end

  create_table "review_criteria", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.string "evaluator_role", default: "both", null: false
    t.string "key", null: false
    t.string "label", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_review_criteria_on_category_id"
    t.index ["key"], name: "index_review_criteria_on_key", unique: true
    t.check_constraint "evaluator_role IN ('both','requester','provider')", name: "review_criteria_evaluator_role_values"
  end

  create_table "review_ratings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "dimension_snapshot"
    t.string "label_snapshot", null: false
    t.boolean "not_applicable", default: false, null: false
    t.integer "rating"
    t.integer "review_criterion_id", null: false
    t.integer "review_id", null: false
    t.datetime "updated_at", null: false
    t.index ["review_criterion_id"], name: "index_review_ratings_on_review_criterion_id"
    t.index ["review_id", "review_criterion_id"], name: "unique_review_rating", unique: true
    t.index ["review_id"], name: "index_review_ratings_on_review_id"
    t.check_constraint "(not_applicable = TRUE AND rating IS NULL) OR (not_applicable = FALSE AND rating BETWEEN 1 AND 5 AND rating IS NOT NULL)", name: "rating_or_na"
  end

  create_table "reviews", force: :cascade do |t|
    t.integer "author_id", null: false
    t.string "completion_answer", null: false
    t.datetime "created_at", null: false
    t.text "factual_body"
    t.datetime "invalidated_at"
    t.datetime "removed_at"
    t.text "response"
    t.datetime "reveal_at", null: false
    t.integer "reviewee_id", null: false
    t.integer "service_request_id", null: false
    t.datetime "updated_at", null: false
    t.boolean "would_reengage", null: false
    t.index ["author_id"], name: "index_reviews_on_author_id"
    t.index ["reviewee_id"], name: "index_reviews_on_reviewee_id"
    t.index ["service_request_id", "author_id"], name: "index_reviews_on_service_request_id_and_author_id", unique: true
    t.index ["service_request_id"], name: "index_reviews_on_service_request_id"
    t.check_constraint "completion_answer IN ('yes','partially','no')", name: "reviews_completion_answer_values"
  end

  create_table "seed_runs", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_seed_runs_on_name", unique: true
  end

  create_table "service_requests", force: :cascade do |t|
    t.json "agreement", default: {}, null: false
    t.integer "agreement_version", default: 0, null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.integer "listing_id", null: false
    t.integer "lock_version", default: 0, null: false
    t.integer "proposed_by_id"
    t.datetime "provider_agreed_at"
    t.datetime "provider_confirmed_at"
    t.integer "provider_id", null: false
    t.datetime "provider_shared_at"
    t.datetime "requester_agreed_at"
    t.datetime "requester_confirmed_at"
    t.integer "requester_id", null: false
    t.datetime "requester_shared_at"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["listing_id", "requester_id"], name: "unique_open_service_request", unique: true, where: "status IN ('pending','accepted','scheduled','awaiting_confirmation','disputed')"
    t.index ["listing_id"], name: "index_service_requests_on_listing_id"
    t.index ["proposed_by_id"], name: "index_service_requests_on_proposed_by_id"
    t.index ["provider_id"], name: "index_service_requests_on_provider_id"
    t.index ["requester_id"], name: "index_service_requests_on_requester_id"
    t.check_constraint "requester_id != provider_id", name: "different_participants"
    t.check_constraint "status IN ('pending','accepted','declined','scheduled','awaiting_confirmation','completed','cancelled','disputed','expired')", name: "service_requests_status_values"
  end

  create_table "studio_assets", force: :cascade do |t|
    t.integer "author_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_studio_assets_on_author_id"
  end

  create_table "studio_versions", force: :cascade do |t|
    t.integer "author_id"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "published_at"
    t.json "settings", default: {}, null: false
    t.string "status", default: "draft", null: false
    t.boolean "system_generated", default: false, null: false
    t.datetime "updated_at", null: false
    t.string "validated_digest"
    t.index ["author_id"], name: "index_studio_versions_on_author_id"
  end

  create_table "testimonials", force: :cascade do |t|
    t.string "consent_version", null: false
    t.datetime "consented_at", null: false
    t.datetime "created_at", null: false
    t.text "decision"
    t.string "display_name_snapshot", null: false
    t.string "kind", null: false
    t.integer "point_reward_claim_id"
    t.string "public_location_snapshot"
    t.datetime "published_at"
    t.text "quote", null: false
    t.datetime "removed_at"
    t.integer "reviewed_by_id"
    t.string "status", default: "submitted", null: false
    t.text "transcript"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["point_reward_claim_id"], name: "index_testimonials_on_point_reward_claim_id"
    t.index ["reviewed_by_id"], name: "index_testimonials_on_reviewed_by_id"
    t.index ["user_id"], name: "index_testimonials_on_user_id"
  end

  create_table "top_listing_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "ends_at"
    t.integer "listing_id", null: false
    t.integer "position", default: 0, null: false
    t.text "reason"
    t.integer "reviewed_by_id"
    t.datetime "starts_at"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["listing_id"], name: "index_top_listing_requests_on_listing_id"
    t.index ["listing_id"], name: "one_top_listing_request", unique: true, where: "status IN ('pending', 'approved')"
    t.index ["reviewed_by_id"], name: "index_top_listing_requests_on_reviewed_by_id"
    t.index ["user_id"], name: "index_top_listing_requests_on_user_id"
  end

  create_table "trust_algorithm_versions", force: :cascade do |t|
    t.datetime "activated_at"
    t.integer "approved_by_id"
    t.json "configuration", default: {}, null: false
    t.datetime "created_at", null: false
    t.integer "created_by_id", null: false
    t.text "explanation", null: false
    t.json "simulation", default: {}, null: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.string "version", null: false
    t.index ["approved_by_id"], name: "index_trust_algorithm_versions_on_approved_by_id"
    t.index ["created_by_id"], name: "index_trust_algorithm_versions_on_created_by_id"
    t.index ["status"], name: "one_active_trust_algorithm", unique: true, where: "status = 'active'"
    t.index ["version"], name: "index_trust_algorithm_versions_on_version", unique: true
  end

  create_table "trust_appeals", force: :cascade do |t|
    t.integer "assigned_to_id"
    t.datetime "created_at", null: false
    t.datetime "decided_at"
    t.text "decision"
    t.integer "referral_id"
    t.datetime "response_due_at", null: false
    t.text "statement", null: false
    t.string "status", default: "open", null: false
    t.integer "trust_score_snapshot_id"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["assigned_to_id"], name: "index_trust_appeals_on_assigned_to_id"
    t.index ["referral_id"], name: "index_trust_appeals_on_referral_id"
    t.index ["trust_score_snapshot_id"], name: "index_trust_appeals_on_trust_score_snapshot_id"
    t.index ["user_id", "referral_id"], name: "one_open_referral_appeal", unique: true, where: "status IN ('open', 'investigating')"
    t.index ["user_id", "trust_score_snapshot_id"], name: "one_open_trust_appeal", unique: true, where: "status IN ('open', 'investigating')"
    t.index ["user_id"], name: "index_trust_appeals_on_user_id"
    t.check_constraint "(trust_score_snapshot_id IS NOT NULL AND referral_id IS NULL) OR (trust_score_snapshot_id IS NULL AND referral_id IS NOT NULL)", name: "one_trust_appeal_source"
  end

  create_table "trust_event_corrections", force: :cascade do |t|
    t.integer "actor_id", null: false
    t.datetime "created_at", null: false
    t.boolean "excluded", null: false
    t.text "reason", null: false
    t.integer "trust_event_id", null: false
    t.index ["actor_id"], name: "index_trust_event_corrections_on_actor_id"
    t.index ["trust_event_id"], name: "index_trust_event_corrections_on_trust_event_id"
  end

  create_table "trust_events", force: :cascade do |t|
    t.integer "actor_id"
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.string "dimension", null: false
    t.string "event_kind", null: false
    t.float "normalized_value", null: false
    t.datetime "occurred_at", null: false
    t.integer "service_request_id"
    t.integer "source_id", null: false
    t.string "source_key", null: false
    t.string "source_type", null: false
    t.integer "subject_id", null: false
    t.index ["actor_id"], name: "index_trust_events_on_actor_id"
    t.index ["category_id"], name: "index_trust_events_on_category_id"
    t.index ["service_request_id"], name: "index_trust_events_on_service_request_id"
    t.index ["source_key"], name: "index_trust_events_on_source_key", unique: true
    t.index ["source_type", "source_id"], name: "index_trust_events_on_source"
    t.index ["subject_id"], name: "index_trust_events_on_subject_id"
    t.check_constraint "normalized_value >= 0 AND normalized_value <= 1", name: "trust_value_bounds"
  end

  create_table "trust_profiles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "trust_score_snapshot_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["trust_score_snapshot_id"], name: "index_trust_profiles_on_trust_score_snapshot_id"
    t.index ["user_id"], name: "index_trust_profiles_on_user_id", unique: true
  end

  create_table "trust_risk_assessments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "decision"
    t.integer "evidence_count", null: false
    t.datetime "expires_at", null: false
    t.integer "reviewed_by_id"
    t.string "signal", null: false
    t.string "status", default: "open", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["reviewed_by_id"], name: "index_trust_risk_assessments_on_reviewed_by_id"
    t.index ["user_id", "signal"], name: "one_open_trust_signal", unique: true, where: "status = 'open'"
    t.index ["user_id"], name: "index_trust_risk_assessments_on_user_id"
  end

  create_table "trust_score_snapshots", force: :cascade do |t|
    t.datetime "calculated_at", null: false
    t.json "contributions", default: [], null: false
    t.datetime "created_at", null: false
    t.string "fingerprint", null: false
    t.json "result", default: {}, null: false
    t.integer "trust_algorithm_version_id", null: false
    t.integer "user_id", null: false
    t.index ["trust_algorithm_version_id"], name: "index_trust_score_snapshots_on_trust_algorithm_version_id"
    t.index ["user_id", "trust_algorithm_version_id", "fingerprint"], name: "unique_trust_calculation", unique: true
    t.index ["user_id"], name: "index_trust_score_snapshots_on_user_id"
  end

  create_table "user_achievements", force: :cascade do |t|
    t.integer "achievement_id", null: false
    t.datetime "created_at", null: false
    t.text "decision"
    t.text "evidence", null: false
    t.string "period_key", null: false
    t.integer "point_operation_id"
    t.integer "point_rule_version_id", null: false
    t.integer "points", null: false
    t.datetime "reviewed_at"
    t.integer "reviewed_by_id"
    t.string "status", default: "submitted", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["achievement_id"], name: "index_user_achievements_on_achievement_id"
    t.index ["point_operation_id"], name: "index_user_achievements_on_point_operation_id"
    t.index ["point_rule_version_id"], name: "index_user_achievements_on_point_rule_version_id"
    t.index ["reviewed_by_id"], name: "index_user_achievements_on_reviewed_by_id"
    t.index ["user_id", "achievement_id", "period_key"], name: "unique_achievement_period", unique: true
    t.index ["user_id"], name: "index_user_achievements_on_user_id"
  end

  create_table "user_blocks", force: :cascade do |t|
    t.integer "blocked_user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["blocked_user_id"], name: "index_user_blocks_on_blocked_user_id"
    t.index ["user_id", "blocked_user_id"], name: "index_user_blocks_on_user_id_and_blocked_user_id", unique: true
    t.index ["user_id"], name: "index_user_blocks_on_user_id"
    t.check_constraint "user_id != blocked_user_id", name: "no_self_block"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.boolean "email_notifications", default: true, null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.integer "pending_referral_link_id"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "member", null: false
    t.string "status", default: "pending", null: false
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["pending_referral_link_id"], name: "index_users_on_pending_referral_link_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role", "status"], name: "index_users_on_role_and_status"
    t.check_constraint "email = lower(trim(email)) AND length(email) > 0", name: "users_normalized_email"
    t.check_constraint "role IN ('member', 'admin', 'super_admin')", name: "users_role"
    t.check_constraint "status IN ('pending', 'active', 'suspended', 'anonymized')", name: "users_status"
  end

  create_table "volunteer_missions", force: :cascade do |t|
    t.text "accommodation"
    t.string "country_code"
    t.datetime "created_at", null: false
    t.integer "daily_contribution_cents", default: 0, null: false
    t.integer "daily_contribution_points", default: 0, null: false
    t.integer "days_off_per_week", default: 2, null: false
    t.text "description"
    t.date "ends_on"
    t.integer "help_hours_per_day", default: 4, null: false
    t.string "languages"
    t.integer "lock_version", default: 0, null: false
    t.text "meals"
    t.integer "minimum_stay_days", default: 1, null: false
    t.integer "organization_id", null: false
    t.text "private_address"
    t.string "public_location"
    t.datetime "published_at"
    t.integer "published_by_id"
    t.string "region"
    t.string "slug", null: false
    t.date "starts_on"
    t.string "status", default: "draft", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "volunteer_capacity", default: 1, null: false
    t.index ["organization_id"], name: "index_volunteer_missions_on_organization_id"
    t.index ["published_by_id"], name: "index_volunteer_missions_on_published_by_id"
    t.index ["slug"], name: "index_volunteer_missions_on_slug", unique: true
    t.check_constraint "daily_contribution_cents BETWEEN 0 AND 1500 AND volunteer_capacity BETWEEN 1 AND 100 AND minimum_stay_days >= 1 AND help_hours_per_day BETWEEN 1 AND 8 AND days_off_per_week BETWEEN 1 AND 6", name: "mission_bounds"
    t.check_constraint "daily_contribution_points >= 0", name: "mission_nonnegative_points"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "admin_permission_grants", "users"
  add_foreign_key "admin_permission_grants", "users", column: "granted_by_id"
  add_foreign_key "admin_permission_grants", "users", column: "revoked_by_id"
  add_foreign_key "audit_logs", "users", column: "actor_id"
  add_foreign_key "bulk_operations", "users", column: "actor_id"
  add_foreign_key "bulk_operations", "users", column: "approved_by_id"
  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "chain_rewards", "chain_rule_versions"
  add_foreign_key "chain_rewards", "chain_services"
  add_foreign_key "chain_rewards", "point_operations"
  add_foreign_key "chain_rewards", "users", column: "recipient_id"
  add_foreign_key "chain_rule_versions", "users", column: "created_by_id"
  add_foreign_key "chain_services", "help_chains"
  add_foreign_key "chain_services", "users", column: "beneficiary_id"
  add_foreign_key "chain_services", "users", column: "provider_id"
  add_foreign_key "comments", "listings"
  add_foreign_key "comments", "users"
  add_foreign_key "community_policy_versions", "users", column: "created_by_id"
  add_foreign_key "content_versions", "users", column: "author_id"
  add_foreign_key "crawler_policies", "users", column: "author_id"
  add_foreign_key "data_requests", "users"
  add_foreign_key "data_requests", "users", column: "approved_by_id"
  add_foreign_key "data_requests", "users", column: "reviewed_by_id"
  add_foreign_key "favorites", "listings"
  add_foreign_key "favorites", "users"
  add_foreign_key "google_identities", "users"
  add_foreign_key "help_chains", "chain_rule_versions"
  add_foreign_key "help_chains", "point_rule_versions"
  add_foreign_key "help_chains", "users", column: "creator_id"
  add_foreign_key "listings", "categories"
  add_foreign_key "listings", "organizations"
  add_foreign_key "listings", "users"
  add_foreign_key "login_blocks", "users", column: "actor_id"
  add_foreign_key "login_sessions", "users"
  add_foreign_key "messages", "service_requests"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "mission_applications", "users"
  add_foreign_key "mission_applications", "volunteer_missions"
  add_foreign_key "mission_messages", "mission_applications"
  add_foreign_key "mission_messages", "users"
  add_foreign_key "notifications", "service_requests"
  add_foreign_key "notifications", "users"
  add_foreign_key "organization_invitations", "organizations"
  add_foreign_key "organization_invitations", "users", column: "accepted_by_id"
  add_foreign_key "organization_invitations", "users", column: "invited_by_id"
  add_foreign_key "organization_memberships", "organizations"
  add_foreign_key "organization_memberships", "users"
  add_foreign_key "organizations", "users", column: "verified_by_id"
  add_foreign_key "partner_entries", "partnership_pages"
  add_foreign_key "partnership_pages", "users", column: "updated_by_id"
  add_foreign_key "point_accounts", "users"
  add_foreign_key "point_adjustments", "point_operations"
  add_foreign_key "point_adjustments", "users"
  add_foreign_key "point_adjustments", "users", column: "approved_by_id"
  add_foreign_key "point_adjustments", "users", column: "proposed_by_id"
  add_foreign_key "point_cycle_progresses", "point_operations"
  add_foreign_key "point_cycle_progresses", "point_rule_versions"
  add_foreign_key "point_cycle_progresses", "users"
  add_foreign_key "point_entries", "point_accounts"
  add_foreign_key "point_entries", "point_operations"
  add_foreign_key "point_operations", "point_operations", column: "reversed_operation_id"
  add_foreign_key "point_operations", "point_rule_versions"
  add_foreign_key "point_operations", "users", column: "initiator_id"
  add_foreign_key "point_reward_claims", "point_operations"
  add_foreign_key "point_reward_claims", "point_rule_versions"
  add_foreign_key "point_reward_claims", "users"
  add_foreign_key "point_reward_claims", "users", column: "reviewed_by_id"
  add_foreign_key "point_rule_versions", "users", column: "created_by_id"
  add_foreign_key "privacy_runs", "retention_policy_versions"
  add_foreign_key "privacy_runs", "users", column: "actor_id"
  add_foreign_key "privacy_runs", "users", column: "approved_by_id"
  add_foreign_key "profiles", "users"
  add_foreign_key "provider_erasure_tasks", "data_requests"
  add_foreign_key "referral_codes", "users", column: "owner_id"
  add_foreign_key "referral_links", "users", column: "owner_id"
  add_foreign_key "referrals", "referral_codes"
  add_foreign_key "referrals", "referral_links"
  add_foreign_key "referrals", "users", column: "referred_user_id"
  add_foreign_key "referrals", "users", column: "referrer_id"
  add_foreign_key "reports", "users", column: "assigned_to_id"
  add_foreign_key "reports", "users", column: "reporter_id"
  add_foreign_key "request_events", "service_requests"
  add_foreign_key "request_events", "users", column: "actor_id"
  add_foreign_key "retention_policy_versions", "users", column: "approved_by_id"
  add_foreign_key "retention_policy_versions", "users", column: "created_by_id"
  add_foreign_key "review_criteria", "categories"
  add_foreign_key "review_ratings", "review_criteria", column: "review_criterion_id"
  add_foreign_key "review_ratings", "reviews"
  add_foreign_key "reviews", "service_requests"
  add_foreign_key "reviews", "users", column: "author_id"
  add_foreign_key "reviews", "users", column: "reviewee_id"
  add_foreign_key "service_requests", "listings"
  add_foreign_key "service_requests", "users", column: "proposed_by_id"
  add_foreign_key "service_requests", "users", column: "provider_id"
  add_foreign_key "service_requests", "users", column: "requester_id"
  add_foreign_key "studio_assets", "users", column: "author_id"
  add_foreign_key "studio_versions", "users", column: "author_id"
  add_foreign_key "testimonials", "point_reward_claims"
  add_foreign_key "testimonials", "users"
  add_foreign_key "testimonials", "users", column: "reviewed_by_id"
  add_foreign_key "top_listing_requests", "listings"
  add_foreign_key "top_listing_requests", "users"
  add_foreign_key "top_listing_requests", "users", column: "reviewed_by_id"
  add_foreign_key "trust_algorithm_versions", "users", column: "approved_by_id"
  add_foreign_key "trust_algorithm_versions", "users", column: "created_by_id"
  add_foreign_key "trust_appeals", "referrals"
  add_foreign_key "trust_appeals", "trust_score_snapshots"
  add_foreign_key "trust_appeals", "users"
  add_foreign_key "trust_appeals", "users", column: "assigned_to_id"
  add_foreign_key "trust_event_corrections", "trust_events"
  add_foreign_key "trust_event_corrections", "users", column: "actor_id"
  add_foreign_key "trust_events", "categories"
  add_foreign_key "trust_events", "service_requests"
  add_foreign_key "trust_events", "users", column: "actor_id"
  add_foreign_key "trust_events", "users", column: "subject_id"
  add_foreign_key "trust_profiles", "trust_score_snapshots"
  add_foreign_key "trust_profiles", "users"
  add_foreign_key "trust_risk_assessments", "users"
  add_foreign_key "trust_risk_assessments", "users", column: "reviewed_by_id"
  add_foreign_key "trust_score_snapshots", "trust_algorithm_versions"
  add_foreign_key "trust_score_snapshots", "users"
  add_foreign_key "user_achievements", "achievements"
  add_foreign_key "user_achievements", "point_operations"
  add_foreign_key "user_achievements", "point_rule_versions"
  add_foreign_key "user_achievements", "users"
  add_foreign_key "user_achievements", "users", column: "reviewed_by_id"
  add_foreign_key "user_blocks", "users"
  add_foreign_key "user_blocks", "users", column: "blocked_user_id"
  add_foreign_key "users", "referral_links", column: "pending_referral_link_id"
  add_foreign_key "volunteer_missions", "organizations"
  add_foreign_key "volunteer_missions", "users", column: "published_by_id"
end
