class CreateScans < ActiveRecord::Migration[8.0]
  def change
    create_table :scans do |t|
      t.references :token, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.integer :risk_score, null: false
      t.integer :risk_level, null: false
      t.text :ai_summary
      t.jsonb :ai_analysis, default: {}
      t.jsonb :flags, default: []
      t.jsonb :holder_snapshot, default: {}
      t.jsonb :liquidity_snapshot, default: {}
      t.integer :scan_type, default: 0
      t.integer :status, default: 0
      t.datetime :completed_at
      t.text :error_message

      t.timestamps
    end

    add_index :scans, [ :token_id, :created_at ]
    add_index :scans, :status
  end
end
