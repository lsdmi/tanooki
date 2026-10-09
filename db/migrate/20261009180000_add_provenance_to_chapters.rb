# frozen_string_literal: true

# Where a chapter was created. Existing rows stay null. Both columns sit next to created_at.
class AddProvenanceToChapters < ActiveRecord::Migration[8.1]
  def change
    change_table :chapters, bulk: true do |t|
      t.string :created_via, limit: 16, after: :created_at
      t.references :api_token, foreign_key: { on_delete: :nullify }, after: :created_via
    end
  end
end
