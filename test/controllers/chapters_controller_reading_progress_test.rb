# frozen_string_literal: true

require 'test_helper'

class ChaptersControllerReadingProgressTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
    @progress = reading_progresses(:one)
    @progress.update!(chapter: chapters(:one))
  end

  test 'show does not write reading progress or reads on a real visit' do
    assert_no_difference -> { ReadingChapterRead.count } do
      get chapter_url(chapters(:two))
    end

    assert_response :success
    assert_equal chapters(:one).id, @progress.reload.chapter_id
  end

  test 'show mounts the client progress recorder for the chapter' do
    get chapter_url(chapters(:two))

    assert_select '[data-controller*=reading-progress]' \
                  '[data-reading-progress-url-value=?]',
                  record_progress_chapter_path(chapters(:two))
  end

  test 'show does not create a reading progress row for an unstarted fiction' do
    @progress.destroy!

    assert_no_difference -> { ReadingProgress.count } do
      get chapter_url(chapters(:two))
    end

    assert_response :success
  end

  test 'show does not advance reading progress on Turbo prefetch' do
    assert_no_difference -> { ReadingChapterRead.count } do
      get chapter_url(chapters(:two)), headers: { 'X-Sec-Purpose' => 'prefetch' }
    end

    assert_response :success
    assert_equal chapters(:one).id, @progress.reload.chapter_id
  end

  test 'engaged moves the resume cursor after a prefetched chapter is actually read' do
    get chapter_url(chapters(:two)), headers: { 'X-Sec-Purpose' => 'prefetch' }

    assert_equal chapters(:one).id, @progress.reload.chapter_id

    post_engaged chapters(:two)

    assert_response :ok
    assert_equal chapters(:two).id, @progress.reload.chapter_id
  end

  test 'engaged sets resume_at' do
    freeze_time do
      post_engaged chapters(:two)

      assert_equal Time.current, @progress.reload.resume_at
    end
  end

  test 'engaged does not mark the chapter read' do
    assert_no_difference [-> { ReadingChapterRead.count }, -> { @progress.reload.completed_count }] do
      post_engaged chapters(:two)
    end
  end

  test 'engaged returns no content when chapter is already the resume cursor' do
    @progress.update!(chapter: chapters(:two))

    post_engaged chapters(:two)

    assert_response :no_content
  end

  test 'record_progress without an engaged event writes nothing' do
    post record_progress_chapter_url(chapters(:two))

    assert_response :unprocessable_content
    assert_equal chapters(:one).id, @progress.reload.chapter_id
  end

  test 'completed inserts a read without moving the resume cursor' do
    ReadingChapterRead.where(user: users(:user_one)).delete_all

    assert_difference -> { ReadingChapterRead.count }, 1 do
      post_completed chapters(:two), source: 'next'
    end

    assert_response :ok
    assert_equal chapters(:one).id, @progress.reload.chapter_id
  end

  test 'completed twice returns no content the second time' do
    post_completed chapters(:one)
    post_completed chapters(:one)

    assert_response :no_content
  end

  test 'completed with an unknown source writes nothing' do
    assert_no_difference -> { ReadingChapterRead.count } do
      post_completed chapters(:one), source: 'open'
    end

    assert_response :unprocessable_content
  end

  test 'completed event cannot claim the manual source' do
    assert_no_difference -> { ReadingChapterRead.count } do
      post_completed chapters(:one), source: 'manual'
    end

    assert_response :unprocessable_content
  end

  test 'next link carries the completion action' do
    get chapter_url(chapters(:one))

    assert_select 'a[href=?][data-action~=?]', chapter_path(chapters(:two)), 'click->reading-progress#next'
  end

  private

  def post_engaged(chapter)
    post record_progress_chapter_url(chapter), params: { event: 'engaged' }, as: :json
  end

  def post_completed(chapter, source: 'scroll')
    post record_progress_chapter_url(chapter), params: { event: 'completed', source: }, as: :json
  end
end
