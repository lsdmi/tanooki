# frozen_string_literal: true

class AddPublishAtToChapters < ActiveRecord::Migration[8.0]
  def change
    add_column :chapters, :publish_at, :datetime, null: true
    add_index :chapters, :publish_at
  end
end
