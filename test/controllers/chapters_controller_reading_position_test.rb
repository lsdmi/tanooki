# frozen_string_literal: true

require 'test_helper'

class ChaptersControllerReadingPositionTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
    @progress = reading_progresses(:one)
    @progress.update!(chapter: chapters(:one))
  end

  test 'engaged stores the locator with the new resume chapter' do
    post_event chapters(:two), event: 'engaged', locator: { percent: 12.5, block_index: 3, quote: 'Початок' }

    assert_response :ok
    assert_equal [chapters(:two).id, 12.5, 'Початок'],
                 @progress.reload.values_at(:chapter_id, :resume_percent, :resume_quote)
  end

  test 'position updates the locator on the resume chapter' do
    post_event chapters(:one), event: 'position', locator: { percent: 64, block_index: 20 }

    assert_response :ok
    assert_equal 20, @progress.reload.resume_block_index
  end

  test 'position on another chapter changes nothing' do
    post_event chapters(:two), event: 'position', locator: { percent: 64 }

    assert_response :no_content
    assert_nil @progress.reload.resume_percent
    assert_equal chapters(:one).id, @progress.chapter_id
  end

  test 'position without a usable locator is rejected' do
    post_event chapters(:one), event: 'position', locator: { quote: 'no percent' }

    assert_response :unprocessable_content
  end

  test 'position with a non-object locator is rejected' do
    post_event chapters(:one), event: 'position', locator: '64'

    assert_response :unprocessable_content
  end

  private

  def post_event(chapter, **params)
    post record_progress_chapter_url(chapter), params:, as: :json
  end
end
