# frozen_string_literal: true

# Drop the stored listing status enum and unused abandoned_at.
class DropListingStatusAndAbandonedAtFromFictions < ActiveRecord::Migration[8.1]
  def up
    change_table :fictions, bulk: true do |t|
      t.remove_index name: 'index_fictions_on_listing_progress'
      t.remove_index name: 'index_fictions_on_status_deleted_created'
      t.remove_index name: 'index_fictions_on_status'
      t.remove :abandoned_at, :status
      t.index %i[completed_at last_chapter_at], name: 'index_fictions_on_listing_progress'
    end
  end

  def down
    change_table :fictions, bulk: true do |t|
      t.remove_index name: 'index_fictions_on_listing_progress'
      t.string :status, null: false, default: 'Анонсовано'
      t.datetime :abandoned_at
      t.index :status
      t.index %i[status deleted_at created_at], name: 'index_fictions_on_status_deleted_created'
      t.index %i[completed_at abandoned_at last_chapter_at], name: 'index_fictions_on_listing_progress'
    end
  end
end
