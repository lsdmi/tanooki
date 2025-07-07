class CreateChatMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :chat_messages do |t|
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false
      t.string :room, null: false, default: 'general'

      t.timestamps
    end

    add_index :chat_messages, :room
    add_index :chat_messages, :created_at
  end
end
