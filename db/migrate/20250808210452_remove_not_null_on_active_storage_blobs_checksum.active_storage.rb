# This migration comes from active_storage (originally 20211119233751)
class RemoveNotNullOnActiveStorageBlobsChecksum < ActiveRecord::Migration[8.0]
  def change
    # Always ensure the table exists
    unless table_exists?(:active_storage_blobs)
      create_table :active_storage_blobs do |t|
        t.string :key, null: false
        t.string :filename, null: false
        t.string :content_type
        t.text :metadata
        t.string :service_name, null: false
        t.bigint :byte_size, null: false
        t.string :checksum
        t.datetime :created_at, null: false
        t.datetime :deleted_at
        t.index [:key], unique: true
      end
    end

    change_column_null(:active_storage_blobs, :checksum, true)
  end
end
