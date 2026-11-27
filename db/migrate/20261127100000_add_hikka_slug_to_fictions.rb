# frozen_string_literal: true

# Hikka (укр. MAL) slug of the novel that matches this fiction. One fiction maps to one Hikka title, and one Hikka
# title maps to at most one fiction: the unique index keeps a second fiction from claiming the same title.
# NULL is allowed for every fiction without a match; MySQL lets many rows hold NULL in a unique index.
class AddHikkaSlugToFictions < ActiveRecord::Migration[8.1]
  def change
    change_table :fictions, bulk: true do |t|
      t.string :hikka_slug, limit: 255, null: true, after: :slug
      t.index :hikka_slug, unique: true, name: 'index_fictions_on_hikka_slug'
    end
  end
end
