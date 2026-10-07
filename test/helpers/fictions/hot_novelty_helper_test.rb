# frozen_string_literal: true

require 'test_helper'

module Fictions
  class HotNoveltyHelperTest < ActionView::TestCase
    include HotNoveltyHelper
    include FormattingHelper

    setup do
      @fiction = fictions(:one)
      @fiction.assign_attributes(chapter_count: 3, last_chapter_at: 4.months.ago)
    end

    test 'the featured copy shows the listing state' do
      assert_equal 'Без оновлень', hot_novelty_featured_copy(@fiction, 3)[:status]
    end

    test 'a licensed work shows the licensed label instead' do
      @fiction.licensed_at = 1.day.ago

      copy = hot_novelty_featured_copy(@fiction, 3)

      assert_equal %w[Ліцензовано Ліценз.], copy.values_at(:status, :status_short)
    end
  end
end
