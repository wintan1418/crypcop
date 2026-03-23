class CreateWalletTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :wallet_transactions do |t|
      t.references :tracked_wallet, null: false, foreign_key: true
      t.references :token, foreign_key: true
      t.string :tx_signature, null: false
      t.integer :tx_type, null: false, default: 0
      t.decimal :amount, precision: 30, scale: 10
      t.decimal :price_usd, precision: 30, scale: 10
      t.decimal :value_usd, precision: 30, scale: 2
      t.string :token_symbol
      t.string :token_mint_address
      t.datetime :transacted_at

      t.timestamps
    end

    add_index :wallet_transactions, :tx_signature, unique: true
    add_index :wallet_transactions, :transacted_at
  end
end
