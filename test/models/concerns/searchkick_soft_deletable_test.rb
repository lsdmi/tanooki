# frozen_string_literal: true

require 'test_helper'

class SearchkickSoftDeletableTest < ActiveSupport::TestCase
  test 'should_index? is false for soft-deleted fiction' do
    fiction = fictions(:one)

    assert_predicate fiction, :should_index?

    Fiction.searchkick_index.stub(:remove, true) do
      fiction.destroy
    end

    assert_not fiction.should_index?
  end

  test 'search_data includes active flag' do
    assert fictions(:one).search_data.fetch(:active)
  end

  test 'searchkick_active_where filters indexed active documents' do
    assert_equal({ active: true }, Fiction.searchkick_active_where)
  end

  test 'hard destroy removes record from search index' do
    fiction = fictions(:one)
    removed = false

    Fiction.searchkick_index.stub(:remove, ->(_) { removed = true }) do
      fiction.really_destroy!
    end

    assert removed
  end
end
