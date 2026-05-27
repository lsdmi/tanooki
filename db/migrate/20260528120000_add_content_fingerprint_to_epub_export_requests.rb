# frozen_string_literal: true

class AddContentFingerprintToEpubExportRequests < ActiveRecord::Migration[8.0]
  def change
    add_column :epub_export_requests, :content_fingerprint, :string, limit: 64, after: :filename
    add_index :epub_export_requests, %i[user_id content_fingerprint],
              name: 'index_epub_export_requests_on_user_id_and_fingerprint'
  end
end
