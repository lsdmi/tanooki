# frozen_string_literal: true

# Soft-deleted fictions point here so their old slug can 301 to the fiction that survived a merge.
class AddMergedIntoToFictions < ActiveRecord::Migration[8.1]
  def change
    add_reference :fictions, :merged_into, null: true,
                  foreign_key: { to_table: :fictions, on_delete: :nullify }, after: :deleted_at
  end
end
