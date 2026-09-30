# frozen_string_literal: true

require 'test_helper'

class GuestReadingMergesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user_two)
    @chapter = chapters(:one)
  end

  test 'merges the posted device records and reports how many changed the account' do
    sign_in @user

    post guest_reading_merge_url, params: { records: [record, { fiction_id: 0, chapter_id: 1 }] }, as: :json

    assert_equal({ 'merged' => 1 }, response.parsed_body)
    assert_equal @chapter.id, ReadingProgress.find_by!(user: @user, fiction: @chapter.fiction).chapter_id
    assert ReadingChapterRead.exists?(user: @user, chapter: @chapter, source: 'device')
  end

  test 'an empty device merges nothing' do
    sign_in @user

    post guest_reading_merge_url, params: { records: [] }, as: :json

    assert_equal({ 'merged' => 0 }, response.parsed_body)
  end

  test 'a body with no records list is rejected' do
    sign_in @user

    post guest_reading_merge_url, params: { records: 'all' }, as: :json

    assert_response :unprocessable_content
  end

  test 'guests cannot merge' do
    assert_no_difference -> { ReadingProgress.count } do
      post guest_reading_merge_url, params: { records: [record] }, as: :json
    end

    assert_response :unauthorized
  end

  private

  def record
    { fiction_id: @chapter.fiction_id, chapter_id: @chapter.id, resume_at: 1.minute.ago.iso8601,
      read_chapter_ids: [@chapter.id], locator: { percent: 25, block_index: 2, quote: 'Текст' } }
  end
end
