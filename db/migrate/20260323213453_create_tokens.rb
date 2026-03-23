class CreateTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :tokens do |t|
      t.string :mint_address, null: false
      t.string :name
      t.string :symbol
      t.text :description
      t.string :image_url
      t.integer :decimals
      t.decimal :supply, precision: 40, scale: 0
      t.string :creator_address
      t.string :mint_authority
      t.string :freeze_authority
      t.boolean :mint_authority_revoked, default: false
      t.boolean :freeze_authority_revoked, default: false
      t.boolean :is_mutable
      t.datetime :created_on_chain_at
      t.datetime :dex_listed_at
      t.decimal :latest_price_usd, precision: 30, scale: 18
      t.decimal :latest_price_sol, precision: 30, scale: 18
      t.decimal :market_cap_usd, precision: 30, scale: 2
      t.decimal :liquidity_usd, precision: 30, scale: 2
      t.decimal :volume_24h_usd, precision: 30, scale: 2
      t.integer :holder_count
      t.decimal :top_10_holder_pct, precision: 5, scale: 2
      t.boolean :lp_locked
      t.datetime :lp_lock_until
      t.integer :risk_score
      t.integer :risk_level, default: 0
      t.datetime :last_scanned_at
      t.datetime :data_fetched_at
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :tokens, :mint_address, unique: true
    add_index :tokens, :creator_address
    add_index :tokens, :risk_level
    add_index :tokens, :created_on_chain_at
    add_index :tokens, :last_scanned_at
  end
end
