# frozen_string_literal: true

require 'test_helper'

module Reading
  class AdDrawerSessionTest < ActiveSupport::TestCase
    test 'opens drawer on first chapter view' do
      assert_open(1, {})
    end

    test 'skips drawer on second chapter view' do
      assert_skips(2, after_views(1))
    end

    test 'skips drawer on third chapter view' do
      assert_skips(3, after_views(2))
    end

    test 'skips drawer on fourth chapter view' do
      assert_skips(4, after_views(3))
    end

    test 'opens drawer on fifth chapter view' do
      assert_open(5, after_views(4))
    end

    test 'opens drawer on ninth chapter view' do
      assert_open(9, after_views(8))
    end

    test 'does not reopen the same chapter on refresh' do
      state = { 'chapter_views' => 1, 'last_chapter_id' => '10' }

      _state, open = AdDrawerSession.call(chapter_id: 10, session_state: state)

      assert_not open
    end

    private

    def after_views(view_count)
      { 'chapter_views' => view_count, 'last_chapter_id' => view_count.to_s }
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
