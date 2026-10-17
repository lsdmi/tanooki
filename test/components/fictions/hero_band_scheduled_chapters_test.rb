# frozen_string_literal: true

require 'test_helper'

module Fictions
  class HeroBandScheduledChaptersTest < ViewComponentTestCase
    setup do
      @fiction = fictions(:one)
    end

    test 'stats skip chapters still on a timer' do
      chapters(:one).update!(published_at: 1.day.from_now, scanlator_ids: chapters(:one).scanlators.ids)
      @fiction.update!(chapter_count: 2)
      presenter = FictionShowPresenter.new(@fiction, nil)

      render_inline(HeroBandComponent.new(fiction: @fiction, presenter:, user: nil))

      assert_selector 'li', text: '1 розділ'
    end
  end
end
