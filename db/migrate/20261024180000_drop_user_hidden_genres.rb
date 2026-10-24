# frozen_string_literal: true

# Packages expanded into genre ids at request time. The per-genre blocklist table is unused.
class DropUserHiddenGenres < ActiveRecord::Migration[8.1]
  def up
    drop_table :user_hidden_genres
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
