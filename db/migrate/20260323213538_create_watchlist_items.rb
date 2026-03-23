class CreateWatchlistItems < ActiveRecord::Migration[8.0]
  def change
    create_table :watchlist_items do |t|
      t.references :user, null: false, foreign_key: true
      t.references :token, null: false, foreign_key: true
      t.boolean :notify_on_risk_change, default: true
      t.boolean :notify_on_price_change, default: false
      t.decimal :price_change_threshold, precision: 5, scale: 2
      t.text :notes

      t.timestamps
    end

    add_index :watchlist_items, [ :user_id, :token_id ], unique: true
  end
end
