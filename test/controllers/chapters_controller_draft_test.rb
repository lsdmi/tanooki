# frozen_string_literal: true

require 'test_helper'

class ChaptersControllerDraftTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
    @fiction = fictions(:one)
    @scheduled = 2.days.from_now.change(min: 0, sec: 0, usec: 0)
  end

  test 'save draft with short content succeeds' do
    assert_difference('Chapter.count', 1) do
      post chapters_url, params: draft_post_params(content: 'short', title: 'Draft short')
    end

    chapter = Chapter.order(:id).last

    assert_predicate chapter, :draft?
    assert_redirected_to edit_chapter_path(chapter)
  end

  test 'publish with short content is unprocessable' do
    assert_no_difference('Chapter.count') do
      post chapters_url, params: publish_post_params(content: 'short', title: 'Too short publish')
    end

    assert_response :unprocessable_content
  end

  test 'draft is absent from guest fiction show list and guest chapter show' do
    post chapters_url, params: draft_post_params(content: 'short', title: 'Hidden draft', number: 99)
    chapter = Chapter.order(:id).last

    sign_out :user
    get fiction_url(@fiction)

    assert_response :success
    assert_select '#chapters-list a[href=?]', chapter_path(chapter), count: 0

    get chapter_url(chapter)

    assert_redirected_to fiction_path(@fiction)
  end

  test 'team readings show lists the draft' do
    post chapters_url, params: draft_post_params(content: 'short', title: 'Listed draft', number: 97)
    chapter = Chapter.order(:id).last

    get reading_url(@fiction)

    assert_response :success
    assert_includes response.body, chapter.display_title
  end

  test 'schedule plus save draft does not schedule' do
    post chapters_url, params: draft_post_params(
      content: 'short',
      title: 'Unscheduled draft',
      number: 96,
      published_at_date: @scheduled.to_date.iso8601,
      published_at_time: @scheduled.strftime('%H:%M')
    )
    chapter = Chapter.order(:id).last

    assert_predicate chapter, :draft?
    assert_nil chapter.published_at
    assert_not chapter.scheduled?
  end

  test 'schedule plus publish still schedules' do
    post chapters_url, params: publish_post_params(
      content: 'x' * 500,
      title: 'Scheduled publish',
      number: 95,
      published_at_date: @scheduled.to_date.iso8601,
      published_at_time: @scheduled.strftime('%H:%M')
    )
    chapter = Chapter.order(:id).last

    assert_predicate chapter, :scheduled?
    assert_redirected_to reading_path(@fiction)
  end

  test 'crafted status published on a draft post does not publish' do
    post chapters_url, params: draft_post_params(
      content: 'short',
      title: 'Crafted status draft',
      number: 94,
      status: 'published'
    )

    assert_predicate Chapter.order(:id).last, :draft?
  end

  test 'missing intent still publishes' do
    post chapters_url, params: {
      chapter: chapter_attrs(content: 'x' * 500, title: 'Implicit publish', number: 93)
    }
    chapter = Chapter.order(:id).last

    assert_predicate chapter, :published?
    assert_redirected_to reading_path(@fiction)
  end

  private

  def draft_post_params(**overrides)
    { intent: 'draft', chapter: chapter_attrs(**overrides) }
  end

  def publish_post_params(**overrides)
    { intent: 'publish', chapter: chapter_attrs(**overrides) }
  end

  def chapter_attrs(**overrides)
    {
      content: 'x' * 500,
      fiction_id: @fiction.id,
      number: 99,
      scanlator_ids: [scanlators(:one).id],
      title: 'Draft chapter'
    }.merge(overrides)
  end
end
