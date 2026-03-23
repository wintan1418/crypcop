class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :stripe_subscription_id, null: false
      t.string :stripe_price_id, null: false
      t.integer :status, null: false, default: 0
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.datetime :canceled_at

      t.timestamps
    end

    add_index :subscriptions, :stripe_subscription_id, unique: true
  end
end
