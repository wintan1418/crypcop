class CreateAlerts < ActiveRecord::Migration[8.0]
  def change
    create_table :alerts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :token, null: false, foreign_key: true
      t.integer :alert_type, null: false
      t.string :title, null: false
      t.text :message, null: false
      t.datetime :read_at
      t.datetime :emailed_at
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :alerts, [ :user_id, :read_at ]
    add_index :alerts, [ :user_id, :created_at ]
  end
end
