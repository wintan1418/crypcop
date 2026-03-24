class CreateVerifiedTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :verified_tokens do |t|
      t.references :token, null: false, foreign_key: true
      t.datetime :verified_at
      t.datetime :expires_at
      t.string :payment_tx
      t.decimal :amount_paid, precision: 10, scale: 2
      t.integer :badge_type, null: false, default: 0
      t.string :contact_email
      t.string :project_url
      t.string :project_name
      t.text :description
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :verified_tokens, :status
  end
end
