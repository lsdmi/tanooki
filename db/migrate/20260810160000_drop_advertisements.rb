# frozen_string_literal: true

class DropAdvertisements < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL.squish
      DELETE FROM active_storage_attachments
      WHERE record_type = 'Advertisement'
    SQL

    drop_table :advertisements, if_exists: true
  end

  def down
    create_table :advertisements do |t|
      t.string :slug, null: false
      t.string :resource, null: false
      t.boolean :enabled, default: false
      t.timestamps
    end

    add_index :advertisements, :enabled
    add_index :advertisements, :slug, unique: true
  end
end
