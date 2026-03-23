class CreateTrackedWallets < ActiveRecord::Migration[8.0]
  def change
    create_table :tracked_wallets do |t|
      t.references :user, null: false, foreign_key: true
      t.string :wallet_address, null: false
      t.string :label
      t.boolean :notify_on_buy, default: true
      t.boolean :notify_on_sell, default: true
      t.boolean :is_whale, default: false
      t.boolean :is_smart_money, default: false
      t.datetime :last_activity_at

      t.timestamps
    end

    add_index :tracked_wallets, :wallet_address
    add_index :tracked_wallets, [ :user_id, :wallet_address ], unique: true
    add_index :tracked_wallets, :is_smart_money
  end
end
