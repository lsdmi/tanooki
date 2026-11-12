# frozen_string_literal: true

require 'test_helper'

class ChapterParagraphReportsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @chapter = chapters(:one)
    @user = users(:user_two)
    @digest = 'c' * ParagraphReport::DIGEST_LENGTH
    sign_in @user
  end

  test 'a reader creates a paragraph report' do
    assert_difference('ParagraphReport.count') do
      post chapter_paragraph_reports_path(@chapter),
           params: { block_index: 1, quote: 'Рядок з помилкою', digest: @digest, message: 'опечатка' },
           as: :json
    end

    assert_response :created
    body = response.parsed_body

    assert_equal(
      [true, 'open', 1, 'Рядок з помилкою'],
      [body['id'].present?, body['status'], body['block_index'], body['quote']]
    )
  end

  test 'the team gets 403' do
    ScanlatorUser.create!(scanlator: scanlators(:one), user: @user)

    post chapter_paragraph_reports_path(@chapter),
         params: { block_index: 0, quote: 'текст', digest: @digest },
         as: :json

    assert_response :forbidden
    assert_equal 'Не можна репортити власний розділ', response.parsed_body['error']
  end

  test 'a draft gets 422' do
    @chapter.update!(status: 'draft')

    post chapter_paragraph_reports_path(@chapter),
         params: { block_index: 0, quote: 'текст', digest: @digest },
         as: :json

    assert_response :unprocessable_content
    assert_equal 'Розділ ще не опубліковано', response.parsed_body['error']
  end

  test 'a duplicate open report gets 422' do
    post chapter_paragraph_reports_path(@chapter),
         params: { block_index: 0, quote: 'текст', digest: @digest },
         as: :json

    post chapter_paragraph_reports_path(@chapter),
         params: { block_index: 0, quote: 'текст', digest: @digest },
         as: :json

    assert_response :unprocessable_content
    assert_equal 'Ви вже повідомили про помилку в цьому абзаці', response.parsed_body['error']
  end

  test 'a guest gets 401 and is sent to login from a page' do
    sign_out @user

    post chapter_paragraph_reports_path(@chapter),
         params: { block_index: 0, quote: 'текст', digest: @digest },
         as: :json

    assert_response :unauthorized

    post chapter_paragraph_reports_path(@chapter),
         params: { block_index: 0, quote: 'текст', digest: @digest }

    assert_redirected_to new_user_session_url
  end

  test 'a missing chapter is 404' do
    post chapter_paragraph_reports_path(chapter_id: 'no-such-chapter'),
         params: { block_index: 0, quote: 'текст', digest: @digest },
         as: :json

    assert_response :not_found
  end

  test 'create is rate limited per user' do
    source = Rails.root.join('app/controllers/chapter_paragraph_reports_controller.rb').read

    assert_includes source, 'rate_limit to: 20, within: 1.minute, by: -> { current_user.id }'
  end
end
