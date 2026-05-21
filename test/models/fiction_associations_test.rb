# frozen_string_literal: true

require 'test_helper'

class FictionAssociationsTest < ActiveSupport::TestCase
  def setup
    @fiction = fictions(:one)
  end

  test 'should destroy associated comments' do
    @fiction.comments << comments(:comment_one)

    assert_difference('Comment.count', -2) { @fiction.destroy }
  end

  test 'should have many fiction genres' do
    assert_instance_of FictionGenre, @fiction.fiction_genres.build
  end

  test 'should have many genres through fiction genres' do
    assert_instance_of Genre, @fiction.genres.build
  end

  test 'should destroy associated fiction genres when destroyed' do
    assert_difference('FictionGenre.count', -1) { @fiction.destroy }
  end

  test 'valid when scanlator_ids unset but scanlator associations exist' do
    @fiction.scanlator_ids = nil

    assert_predicate @fiction, :valid?
  end

  test 'invalid when scanlator_ids cleared and no scanlator associations' do
    @fiction.fiction_scanlators.destroy_all
    @fiction.scanlator_ids = []

    assert_not @fiction.valid?
    assert_includes @fiction.errors[:scanlator_ids],
                    I18n.t('activerecord.errors.models.fiction.attributes.scanlator_ids.blank')
  end
end
