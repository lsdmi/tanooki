# frozen_string_literal: true

require 'test_helper'

class HotLookupIndexesTest < ActiveSupport::TestCase
  setup do
    @connection = ActiveRecord::Base.connection
  end

  test 'hot lookup indexes exist' do
    assert @connection.index_exists?(:scanlators, :slug, unique: true)
    assert @connection.index_exists?(:chapters, %i[fiction_id deleted_at published_at])
    assert @connection.index_exists?(:fictions, %i[status deleted_at created_at])
  end

  test 'scanlator slug lookup uses slug index' do
    assert_index_used(
      Scanlator.where(slug: scanlators(:one).slug).to_sql,
      'index_scanlators_on_slug'
    )
  end

  test 'released chapters composite index is available to the planner' do
    fiction = fictions(:one)
    sql = Chapter.where(fiction_id: fiction.id).merge(Chapter.released).to_sql
    possible_keys = explain_possible_keys(sql)

    assert_includes possible_keys, 'index_chapters_on_fiction_deleted_published'
  end

  test 'fiction status lists use status deleted created index' do
    sql = Fiction.where(status: 'Видається').order(created_at: :desc).limit(20).to_sql

    assert_index_used(sql, 'index_fictions_on_status_deleted_created')
  end

  private

  def assert_index_used(sql, expected_index)
    plan = @connection.exec_query("EXPLAIN #{sql}")
    keys = plan.pluck('key')

    assert_includes keys, expected_index, "expected #{expected_index} in EXPLAIN keys #{keys.inspect}"
  end

  def explain_possible_keys(sql)
    @connection.exec_query("EXPLAIN #{sql}").flat_map do |row|
      row['possible_keys']&.split(/\s*,\s*/) || []
    end
  end
end
