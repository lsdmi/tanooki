# frozen_string_literal: true

require 'test_helper'

module Fictions
  class ReadThroughsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @user = users(:user_one)
      @fiction = fictions(:one)
      ReadingChapterRead.where(user: @user).delete_all
      reading_progresses(:one).update!(chapter: chapters(:one), status: :active, resume_percent: nil,
                                       resume_at: Time.current)
      @third = Chapter.create!(fiction: @fiction, user: @user, title: 'Chapter 3', number: 3, content: 'x' * 500,
                               scanlator_ids: [scanlators(:one).id])
      sign_in @user
    end

    test 'marks the range and answers with the toast text and an undo token' do
      mark_through(chapters(:two))

      assert_equal 'Розділи 1–2 позначено прочитаними', reply['message']
      assert_predicate reply['undo'], :present?
      assert_equal [chapters(:one), chapters(:two)].map(&:id).sort, read_chapter_ids.sort
    end

    test 'the streams replace the loaded rows of the range and move continue past it' do
      mark_through(chapters(:two))
      streams = Nokogiri::HTML.fragment(reply['streams'])

      rows = [chapters(:one), chapters(:two), @third].map { |chapter| "chapter_list_chapter_#{chapter.id}" }

      assert_equal rows.sort, streams.css('turbo-stream[target^=chapter_list_chapter_]').pluck('target').sort
      assert_match(/До поточного розділу · 3/, streams.at_css('turbo-stream[target=chapter_continue_chip]').to_html)
    end

    test 'undo removes only what the mark added' do
      ReadingChapterRead.create!(user: @user, fiction: @fiction, chapter: chapters(:two), completed_at: Time.current,
                                 source: 'scroll')
      mark_through(@third)
      delete fiction_read_through_url(@fiction), params: { undo: reply['undo'], row_ids: [@third.id] }, as: :json

      assert_response :success
      assert_equal [chapters(:two).id], read_chapter_ids
    end

    test 'undo rejects a token minted for another user' do
      mark_through(chapters(:two))
      token = reply['undo']
      sign_in users(:user_two)
      delete fiction_read_through_url(@fiction), params: { undo: token }, as: :json

      assert_response :unprocessable_content
      assert_equal 2, read_chapter_ids.size
    end

    test 'guests are sent to log in' do
      sign_out @user
      post fiction_read_through_url(@fiction), params: { chapter_id: chapters(:two).id }

      assert_redirected_to new_user_session_path
    end

    private

    def mark_through(chapter)
      post fiction_read_through_url(@fiction),
           params: { chapter_id: chapter.id, row_ids: [chapters(:one), chapters(:two), @third].map(&:id) }, as: :json
    end

    def reply = response.parsed_body

    def read_chapter_ids
      ReadingChapterRead.where(user: @user, fiction: @fiction).pluck(:chapter_id)
    end
  end
end
