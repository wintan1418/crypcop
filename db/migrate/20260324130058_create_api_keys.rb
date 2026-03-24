class CreateApiKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :api_keys do |t|
      t.references :user, null: false, foreign_key: true
      t.string :key, null: false
      t.string :name
      t.integer :tier, null: false, default: 0
      t.integer :calls_today, null: false, default: 0
      t.integer :calls_limit, null: false, default: 100
      t.datetime :last_used_at
      t.boolean :active, null: false, default: true
      t.datetime :calls_reset_at

      t.timestamps
    end

    add_index :api_keys, :key, unique: true
  end
end
