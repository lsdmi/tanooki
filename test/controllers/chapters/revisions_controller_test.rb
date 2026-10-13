# frozen_string_literal: true

require 'test_helper'

module Chapters
  class RevisionsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @chapter = chapters(:one)
      @chapter.update!(status: :draft, title: 'Зараз', content: '<p>Новий абзац історії.</p>')
      @revision = ChapterRevision.create!(
        chapter: @chapter, user: users(:user_one), title: 'Було', body: '<p>Старий абзац історії.</p>'
      )
    end

    test 'the editor lists a stored revision and what changed' do
      sign_in users(:user_one)

      get edit_chapter_url(@chapter)

      assert_response :success
      assert_select 'h2', text: I18n.t('chapters.revisions.title')
      assert_includes response.body, 'Старий абзац історії'
    end

    test 'restore puts the chapter back to that revision' do
      sign_in users(:user_one)

      post revert_chapter_revision_url(@chapter, @revision)

      assert_redirected_to edit_chapter_path(@chapter)
      assert_equal 'Було', @chapter.reload.title
      assert_includes @chapter.content_html, 'Старий абзац історії'
    end

    test 'someone who does not manage the chapter cannot restore it' do
      sign_in users(:user_two)

      post revert_chapter_revision_url(@chapter, @revision)

      assert_redirected_to root_path
    end

    teardown do
      user = users(:user_one)
      Rails.cache.delete(Api::Limits.counter_key(:published_edit_hour, user, Api::Limits::PublishedEdits.hour_period))
    end

    test 'a published chapter restore stops at the hourly edit cap' do
      sign_in users(:user_one)
      @chapter.update!(status: :published, content: "#{'А' * 500}.")
      fill_published_edit_hour

      post revert_chapter_revision_url(@chapter, @revision)

      assert_redirected_to edit_chapter_path(@chapter)
      assert_match(/60 на годину/, flash[:alert])
    end

    private

    def fill_published_edit_hour
      Rails.cache.write(
        Api::Limits.counter_key(:published_edit_hour, users(:user_one), Api::Limits::PublishedEdits.hour_period),
        Api::Limits::PUBLISHED_EDITS_PER_HOUR
      )
    end
  end
end
