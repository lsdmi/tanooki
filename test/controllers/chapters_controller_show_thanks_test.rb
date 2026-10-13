# frozen_string_literal: true

require 'test_helper'

class ChaptersControllerShowThanksTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @chapter = chapters(:one)
    ChapterThank.where(chapter: @chapter).delete_all
  end

  test 'a guest sees the login CTA on the thanks block' do
    get chapter_url(@chapter)

    assert_response :success
    assert_select '#chapter-thanks', text: /Увійдіть, щоб подякувати перекладачам/
  end

  test 'the team sees the reader thanks count without a button' do
    sign_in users(:user_one)

    get chapter_url(@chapter)

    assert_select '#chapter-thanks', text: /Подяки читачів/
    assert_select '#chapter-thanks button', count: 0
  end

  test 'a reader sees the thanks button right after the chapter text' do
    sign_in users(:user_two)

    get chapter_url(@chapter)

    assert_select '#user-content + #chapter-thanks button[data-action*=chapter-thanks]', text: /Дякую/
  end

  test 'an 18+ locked chapter blurs the thanks bar with the prose' do
    sign_in users(:user_two)
    @chapter.fiction.update!(content_rating: :eighteen)

    get chapter_url(@chapter)

    assert_select '.adult-content-gate--locked #chapter-thanks.chapter-thanks-bar'
  end
end
