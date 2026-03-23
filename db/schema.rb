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

ActiveRecord::Schema[8.0].define(version: 2026_03_23_230310) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "alerts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "token_id", null: false
    t.integer "alert_type", null: false
    t.string "title", null: false
    t.text "message", null: false
    t.datetime "read_at"
    t.datetime "emailed_at"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token_id"], name: "index_alerts_on_token_id"
    t.index ["user_id", "created_at"], name: "index_alerts_on_user_id_and_created_at"
    t.index ["user_id", "read_at"], name: "index_alerts_on_user_id_and_read_at"
    t.index ["user_id"], name: "index_alerts_on_user_id"
  end

  create_table "portfolio_holdings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "token_id"
    t.string "wallet_address", null: false
    t.string "token_mint_address"
    t.string "token_symbol"
    t.string "token_name"
    t.decimal "amount", precision: 30, scale: 10
    t.decimal "value_usd", precision: 30, scale: 2
    t.integer "risk_score"
    t.integer "risk_level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token_id"], name: "index_portfolio_holdings_on_token_id"
    t.index ["user_id", "wallet_address"], name: "index_portfolio_holdings_on_user_id_and_wallet_address"
    t.index ["user_id"], name: "index_portfolio_holdings_on_user_id"
  end

  create_table "scans", force: :cascade do |t|
    t.bigint "token_id", null: false
    t.bigint "user_id"
    t.integer "risk_score", null: false
    t.integer "risk_level", null: false
    t.text "ai_summary"
    t.jsonb "ai_analysis", default: {}
    t.jsonb "flags", default: []
    t.jsonb "holder_snapshot", default: {}
    t.jsonb "liquidity_snapshot", default: {}
    t.integer "scan_type", default: 0
    t.integer "status", default: 0
    t.datetime "completed_at"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_scans_on_status"
    t.index ["token_id", "created_at"], name: "index_scans_on_token_id_and_created_at"
    t.index ["token_id"], name: "index_scans_on_token_id"
    t.index ["user_id"], name: "index_scans_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "stripe_subscription_id", null: false
    t.string "stripe_price_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "current_period_start"
    t.datetime "current_period_end"
    t.datetime "canceled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stripe_subscription_id"], name: "index_subscriptions_on_stripe_subscription_id", unique: true
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "tokens", force: :cascade do |t|
    t.string "mint_address", null: false
    t.string "name"
    t.string "symbol"
    t.text "description"
    t.string "image_url"
    t.integer "decimals"
    t.decimal "supply", precision: 40
    t.string "creator_address"
    t.string "mint_authority"
    t.string "freeze_authority"
    t.boolean "mint_authority_revoked", default: false
    t.boolean "freeze_authority_revoked", default: false
    t.boolean "is_mutable"
    t.datetime "created_on_chain_at"
    t.datetime "dex_listed_at"
    t.decimal "latest_price_usd", precision: 30, scale: 18
    t.decimal "latest_price_sol", precision: 30, scale: 18
    t.decimal "market_cap_usd", precision: 30, scale: 2
    t.decimal "liquidity_usd", precision: 30, scale: 2
    t.decimal "volume_24h_usd", precision: 30, scale: 2
    t.integer "holder_count"
    t.decimal "top_10_holder_pct", precision: 5, scale: 2
    t.boolean "lp_locked"
    t.datetime "lp_lock_until"
    t.integer "risk_score"
    t.integer "risk_level", default: 0
    t.datetime "last_scanned_at"
    t.datetime "data_fetched_at"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_on_chain_at"], name: "index_tokens_on_created_on_chain_at"
    t.index ["creator_address"], name: "index_tokens_on_creator_address"
    t.index ["last_scanned_at"], name: "index_tokens_on_last_scanned_at"
    t.index ["mint_address"], name: "index_tokens_on_mint_address", unique: true
    t.index ["risk_level"], name: "index_tokens_on_risk_level"
  end

  create_table "tracked_wallets", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "wallet_address", null: false
    t.string "label"
    t.boolean "notify_on_buy", default: true
    t.boolean "notify_on_sell", default: true
    t.boolean "is_whale", default: false
    t.boolean "is_smart_money", default: false
    t.datetime "last_activity_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_smart_money"], name: "index_tracked_wallets_on_is_smart_money"
    t.index ["user_id", "wallet_address"], name: "index_tracked_wallets_on_user_id_and_wallet_address", unique: true
    t.index ["user_id"], name: "index_tracked_wallets_on_user_id"
    t.index ["wallet_address"], name: "index_tracked_wallets_on_wallet_address"
  end

  create_table "trust_votes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "token_id", null: false
    t.integer "vote", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token_id"], name: "index_trust_votes_on_token_id"
    t.index ["user_id", "token_id"], name: "index_trust_votes_on_user_id_and_token_id", unique: true
    t.index ["user_id"], name: "index_trust_votes_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "tier", default: 0, null: false
    t.integer "daily_scan_count", default: 0, null: false
    t.datetime "daily_scan_reset_at"
    t.string "stripe_customer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "telegram_chat_id"
    t.string "telegram_username"
    t.datetime "telegram_linked_at"
    t.string "telegram_link_token"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "wallet_transactions", force: :cascade do |t|
    t.bigint "tracked_wallet_id", null: false
    t.bigint "token_id"
    t.string "tx_signature", null: false
    t.integer "tx_type", default: 0, null: false
    t.decimal "amount", precision: 30, scale: 10
    t.decimal "price_usd", precision: 30, scale: 10
    t.decimal "value_usd", precision: 30, scale: 2
    t.string "token_symbol"
    t.string "token_mint_address"
    t.datetime "transacted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token_id"], name: "index_wallet_transactions_on_token_id"
    t.index ["tracked_wallet_id"], name: "index_wallet_transactions_on_tracked_wallet_id"
    t.index ["transacted_at"], name: "index_wallet_transactions_on_transacted_at"
    t.index ["tx_signature"], name: "index_wallet_transactions_on_tx_signature", unique: true
  end

  create_table "watchlist_items", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "token_id", null: false
    t.boolean "notify_on_risk_change", default: true
    t.boolean "notify_on_price_change", default: false
    t.decimal "price_change_threshold", precision: 5, scale: 2
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token_id"], name: "index_watchlist_items_on_token_id"
    t.index ["user_id", "token_id"], name: "index_watchlist_items_on_user_id_and_token_id", unique: true
    t.index ["user_id"], name: "index_watchlist_items_on_user_id"
  end

  add_foreign_key "alerts", "tokens"
  add_foreign_key "alerts", "users"
  add_foreign_key "portfolio_holdings", "tokens"
  add_foreign_key "portfolio_holdings", "users"
  add_foreign_key "scans", "tokens"
  add_foreign_key "scans", "users"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "tracked_wallets", "users"
  add_foreign_key "trust_votes", "tokens"
  add_foreign_key "trust_votes", "users"
  add_foreign_key "wallet_transactions", "tokens"
  add_foreign_key "wallet_transactions", "tracked_wallets"
  add_foreign_key "watchlist_items", "tokens"
  add_foreign_key "watchlist_items", "users"
end
