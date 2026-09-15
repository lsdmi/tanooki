# frozen_string_literal: true

# Draft vs published lifecycle for user-authored rich text (chapters, publications).
class AddStatusToChaptersAndPublications < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    add_status_column :chapters, after: :views
    add_status_column :publications, after: :views
    add_online_index :chapters, %i[fiction_id deleted_at status published_at],
                     name: 'index_chapters_on_fiction_deleted_status_published'
    add_online_index :publications, %i[deleted_at status],
                     name: 'index_publications_on_deleted_status'
  end

  def down
    remove_online_index :chapters, 'index_chapters_on_fiction_deleted_status_published'
    remove_online_index :publications, 'index_publications_on_deleted_status'
    remove_column :chapters, :status if column_exists?(:chapters, :status)
    remove_column :publications, :status if column_exists?(:publications, :status)
  end

  private

  def add_status_column(table, after:)
    return if column_exists?(table, :status)

    add_column table, :status, :string, limit: 16, null: false, default: 'published', after: after
  end

  def add_online_index(table, columns, name:)
    return if index_exists?(table, columns, name: name)

    column_list = Array(columns).map { |column| quote_column_name(column) }.join(', ')

    execute <<~SQL.squish
      ALTER TABLE #{quote_table_name(table)}
      ADD INDEX #{quote_column_name(name)} (#{column_list}),
      ALGORITHM=INPLACE, LOCK=NONE
    SQL
  end

  def remove_online_index(table, name)
    return unless index_exists?(table, name:)

    execute <<~SQL.squish
      ALTER TABLE #{quote_table_name(table)}
      DROP INDEX #{quote_column_name(name)},
      ALGORITHM=INPLACE, LOCK=NONE
    SQL
  end
end
