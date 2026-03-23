class CreateTrustVotes < ActiveRecord::Migration[8.0]
  def change
    create_table :trust_votes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :token, null: false, foreign_key: true
      t.integer :vote, null: false

      t.timestamps
    end

    add_index :trust_votes, [ :user_id, :token_id ], unique: true
  end
end
