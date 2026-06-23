# frozen_string_literal: true

require 'test_helper'

class SoftDeletableTest < ActiveSupport::TestCase
  test 'destroy soft deletes by setting deleted_at' do
    fiction = fictions(:one)
    fiction.destroy

    assert_predicate fiction, :deleted?
    assert_not Fiction.exists?(fiction.id)
    assert Fiction.with_deleted.exists?(fiction.id)
  end

  test 'only_deleted returns soft-deleted records' do
    fiction = fictions(:one)
    fiction.destroy

    assert_includes Fiction.only_deleted, fiction
    assert_not_includes Fiction.all, fiction
  end

  test 'really_destroy! hard deletes the record' do
    fiction = fictions(:two)
    removed = false

    Fiction.searchkick_index.stub(:remove, ->(_) { removed = true }) do
      fiction.really_destroy!
    end

    assert removed
    assert_not Fiction.with_deleted.exists?(fiction.id)
  end

  test 'destroy hard deletes non-soft-deletable associations' do
    fiction = fictions(:one)
    fiction.comments << comments(:comment_one)

    assert_difference('Comment.count', -2) { fiction.destroy }
  end

  test 'destroy soft deletes soft-deletable child records' do
    fiction = fictions(:one)
    chapter = chapters(:one)

    assert_difference('Chapter.count', -2) { fiction.destroy }

    assert_predicate Chapter.with_deleted.find(chapter.id), :deleted?
  end
end
