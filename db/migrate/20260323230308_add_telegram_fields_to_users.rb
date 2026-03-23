class AddTelegramFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :telegram_chat_id, :string
    add_column :users, :telegram_username, :string
    add_column :users, :telegram_linked_at, :datetime
    add_column :users, :telegram_link_token, :string
  end
end
