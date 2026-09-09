# frozen_string_literal: true

require 'test_helper'

class FictionListQueryBuilderTest < ActiveSupport::TestCase
  setup do
    @finished = fictions(:one)
    @open = fictions(:two)
    @finished.scanlator_ids = @finished.scanlators.ids
    @open.scanlator_ids = @open.scanlators.ids
    @finished.update!(completed_at: Time.current)
    @open.update!(completed_at: nil)
  end

  test 'finished filter uses listing_finished not status' do
    @finished.update!(status: :ongoing)

    ids = FictionListQueryBuilder.new(Fiction.all, finished: '1').call.map(&:id)

    assert_includes ids, @finished.id
    assert_not_includes ids, @open.id
  end

  test 'without finished filter both listings remain' do
    ids = FictionListQueryBuilder.new(Fiction.all, {}).call.map(&:id)

    assert_includes ids, @finished.id
    assert_includes ids, @open.id
  end
end
