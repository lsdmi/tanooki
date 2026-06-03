# frozen_string_literal: true

require 'test_helper'

module Reading
  class AdDrawerSessionTest < ActiveSupport::TestCase
    test 'opens on 1st 6th and 11th chapter view in session' do
      assert_open(1, {})
      assert_skips(2, after_views(1))
      assert_skips(3, after_views(2))
      assert_skips(4, after_views(3))
      assert_skips(5, after_views(4))
      assert_open(6, after_views(5))
      assert_open(11, after_views(10))
    end

    test 'does not reopen the same chapter on refresh' do
      state = { 'chapter_views' => 1, 'last_chapter_id' => '10' }

      _state, open = AdDrawerSession.call(chapter_id: 10, session_state: state)

      assert_not open
    end

    private

    def after_views(n)
      { 'chapter_views' => n, 'last_chapter_id' => n.to_s }
    end

    def assert_open(chapter_id, state)
      new_state, open = AdDrawerSession.call(chapter_id: chapter_id, session_state: state)

      assert open, "expected chapter #{chapter_id} to open drawer"
      assert_equal chapter_id.to_s, new_state['last_chapter_id']
    end

    def assert_skips(chapter_id, state)
      _state, open = AdDrawerSession.call(chapter_id: chapter_id, session_state: state)

      assert_not open, "expected chapter #{chapter_id} to skip drawer"
    end
  end
end
