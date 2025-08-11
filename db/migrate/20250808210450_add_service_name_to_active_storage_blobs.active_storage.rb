# This migration comes from active_storage (originally 20190112182829)
class AddServiceNameToActiveStorageBlobs < ActiveRecord::Migration[8.0]
  def up
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

    # Always add the column if it doesn't exist
    unless column_exists?(:active_storage_blobs, :service_name)
      add_column :active_storage_blobs, :service_name, :string
    end

    # Set default service name for existing records
    if configured_service = ActiveStorage::Blob.service.name
      ActiveStorage::Blob.unscoped.update_all(service_name: configured_service)
    end

    # Always make the column not null
    change_column :active_storage_blobs, :service_name, :string, null: false
  end

  def down
    return unless table_exists?(:active_storage_blobs)

    remove_column :active_storage_blobs, :service_name
  end
end
