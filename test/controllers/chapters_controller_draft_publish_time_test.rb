# frozen_string_literal: true

require 'test_helper'

class ChaptersControllerDraftPublishTimeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
    @fiction = fictions(:one)
  end

  test 'publishing a draft uses the current time not created_at' do
    travel_to 3.days.ago do
      post chapters_url, params: {
        intent: 'draft',
        chapter: chapter_attrs(title: 'Old draft', number: 92)
      }
    end
    chapter = Chapter.order(:id).last

    patch chapter_url(chapter), params: {
      intent: 'publish',
      chapter: chapter_attrs(title: 'Old draft', number: 92)
    }
    chapter.reload

    assert_predicate chapter, :published?
    assert_in_delta Time.current, chapter.published_at, 2.seconds
    assert_in_delta Time.current, chapter.public_at, 2.seconds
  end

  private

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
