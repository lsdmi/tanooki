# frozen_string_literal: true

class CreateEpubExportRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :epub_export_requests do |t|
      t.references :user, foreign_key: true
      t.string :token, null: false
      t.integer :status, null: false, default: 0
      t.json :rich_text_ids, null: false
      t.string :volume_title
      t.string :filename
      t.text :error_message
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :epub_export_requests, :token, unique: true
    add_index :epub_export_requests, :status
    add_index :epub_export_requests, :expires_at
  end
end
