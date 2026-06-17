# frozen_string_literal: true

# Online-safe indexes for slug lookups, released-chapter filters, and soft-delete scopes.
class AddHotLookupIndexes < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    add_online_index :scanlators, :slug, unique: true, name: 'index_scanlators_on_slug'
    add_online_index :chapters, %i[fiction_id deleted_at published_at],
                     name: 'index_chapters_on_fiction_deleted_published'
    add_online_index :fictions, %i[status deleted_at created_at],
                     name: 'index_fictions_on_status_deleted_created'
  end

  def down
    remove_online_index :fictions, 'index_fictions_on_status_deleted_created'
    remove_online_index :chapters, 'index_chapters_on_fiction_deleted_published'
    remove_online_index :scanlators, 'index_scanlators_on_slug'
  end

  private

  def add_online_index(table, columns, name:, unique: false)
    return if index_exists?(table, columns, name: name)

    column_list = Array(columns).map { |column| quote_column_name(column) }.join(', ')
    unique_clause = unique ? 'UNIQUE ' : ''

    execute <<~SQL.squish
      ALTER TABLE #{quote_table_name(table)}
      ADD #{unique_clause}INDEX #{quote_column_name(name)} (#{column_list}),
      ALGORITHM=INPLACE, LOCK=NONE
    SQL
  end

  def remove_online_index(table, name)
    return unless index_exists?(table, name)

    execute <<~SQL.squish
      ALTER TABLE #{quote_table_name(table)}
      DROP INDEX #{quote_column_name(name)},
      ALGORITHM=INPLACE, LOCK=NONE
    SQL
  end
end
