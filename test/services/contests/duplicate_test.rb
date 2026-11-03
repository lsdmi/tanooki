# frozen_string_literal: true

require 'test_helper'

module Contests
  class DuplicateTest < ActiveSupport::TestCase
    setup do
      @source = contests(:results)
      @source.update!(tagline: 'Старий слоган', description: 'Стара тема')
      @draft = Duplicate.call(contest: @source, weeks_until_open: 4)
    end

    test 'shifts all dates by the same delta' do
      shift = @draft.submissions_open_at - @source.submissions_open_at

      assert_in_delta shift, @draft.announced_at - @source.announced_at, 1
      assert_in_delta shift, @draft.submissions_close_at - @source.submissions_close_at, 1
      assert_in_delta shift, @draft.judging_close_at - @source.judging_close_at, 1
    end

    test 'links to the source and stays unpublished' do
      assert_equal @source.id, @draft.source_contest_id
      assert_nil @draft.published_at
    end

    test 'clears theme fields' do
      assert_not @draft.cover.attached?
      assert_not_equal @source.tagline, @draft.tagline
      assert_predicate @draft.description.body, :blank?
    end

    test 'copies prizes' do
      assert_equal @source.prizes.count, @draft.prizes.count
    end
  end
end
