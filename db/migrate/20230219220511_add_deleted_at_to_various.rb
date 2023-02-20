class AddDeletedAtToVarious < ActiveRecord::Migration[7.0]
  def change
    add_column :action_text_rich_texts, :deleted_at, :datetime
    add_column :active_storage_attachments, :deleted_at, :datetime
    add_column :active_storage_blobs, :deleted_at, :datetime
  end
end
