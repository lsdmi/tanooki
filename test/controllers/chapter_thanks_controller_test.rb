# frozen_string_literal: true

require 'test_helper'

class ChapterThanksControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @chapter = chapters(:one)
    sign_in users(:user_two)
  end

  test 'a reader thanks a chapter and gets the count label' do
    assert_difference('ChapterThank.count') { post chapter_thanks_path(@chapter), as: :json }

    assert_response :success
    assert_equal({ 'thanked' => true, 'thanks_count' => 1, 'thanks_count_label' => '1 подяка' }, response.parsed_body)
  end

  test 'a second tap takes the thanks back' do
    post chapter_thanks_path(@chapter), as: :json

    assert_difference('ChapterThank.count', -1) { post chapter_thanks_path(@chapter), as: :json }
    assert_equal({ 'thanked' => false, 'thanks_count' => 0, 'thanks_count_label' => '0 подяк' }, response.parsed_body)
  end

  test 'the team gets 403' do
    ScanlatorUser.create!(scanlator: scanlators(:one), user: users(:user_two))

    post chapter_thanks_path(@chapter), as: :json

    assert_response :forbidden
    assert_equal 'Не можна дякувати за власний розділ', response.parsed_body['error']
  end

  test 'a draft gets 422' do
    @chapter.update!(status: 'draft')

    post chapter_thanks_path(@chapter), as: :json

    assert_response :unprocessable_content
  end

  test 'a guest gets 401 and is sent to login from a page' do
    sign_out users(:user_two)

    post chapter_thanks_path(@chapter), as: :json

    assert_response :unauthorized

    post chapter_thanks_path(@chapter)

    assert_redirected_to new_user_session_url
  end

  test 'a missing chapter is 404' do
    post chapter_thanks_path(chapter_id: 'no-such-chapter'), as: :json

    assert_response :not_found
  end
end
