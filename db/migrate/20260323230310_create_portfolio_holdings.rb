class CreatePortfolioHoldings < ActiveRecord::Migration[8.0]
  def change
    create_table :portfolio_holdings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :token, foreign_key: true
      t.string :wallet_address, null: false
      t.string :token_mint_address
      t.string :token_symbol
      t.string :token_name
      t.decimal :amount, precision: 30, scale: 10
      t.decimal :value_usd, precision: 30, scale: 2
      t.integer :risk_score
      t.integer :risk_level

      t.timestamps
    end

    add_index :portfolio_holdings, [ :user_id, :wallet_address ]
  end
end
