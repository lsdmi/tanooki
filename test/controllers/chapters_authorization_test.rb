# frozen_string_literal: true

require 'test_helper'

class ChaptersAuthorizationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def chapter_params(overrides = {})
    {
      content: 'x' * 500,
      fiction_id: fictions(:one).id,
      scanlator_ids: [scanlators(:two).id],
      title: 'Chapter'
    }.merge(overrides)
  end

  test 'guest cannot create chapter' do
    assert_no_difference('Chapter.count') do
      post chapters_url, params: {
        chapter: chapter_params(
          number: 99,
          scanlator_ids: [scanlators(:one).id],
          title: 'Guest chapter'
        )
      }
    end

    assert_redirected_to new_user_session_path
  end

  test 'scanlator member can get new chapter form for fiction their team has not joined' do
    sign_in users(:user_two)

    get new_chapter_url(fiction: fictions(:one).slug)

    assert_response :success
  end

  test 'scanlator member can create chapter on fiction using own team' do
    sign_in users(:user_two)
    fiction = fictions(:one)

    assert_difference('Chapter.count') do
      post chapters_url, params: {
        chapter: chapter_params(number: 95, title: 'Alternative translation chapter')
      }
    end

    assert_redirected_to reading_path(fiction)
  end

  test 'user_id spoof is ignored on chapter create' do
    sign_in users(:user_two)

    post chapters_url, params: {
      chapter: chapter_params(number: 93, title: 'Spoofed author chapter', user_id: users(:user_one).id)
    }

    assert_equal users(:user_two).id, Chapter.order(:id).last.user_id
  end

  test 'scanlator member cannot create chapter with only foreign team ids' do
    sign_in users(:user_two)
    fiction = fictions(:one)

    assert_no_difference('Chapter.count') do
      post chapters_url, params: {
        chapter: chapter_params(
          fiction_id: fiction.id,
          number: 99,
          scanlator_ids: [scanlators(:one).id],
          title: 'Foreign team chapter'
        )
      }
    end

    assert_redirected_to root_path
    assert_equal [scanlators(:one).id], fiction.reload.scanlators.ids.sort
  end

  test 'scanlator member cannot create chapter without scanlator ids on unlinked fiction' do
    sign_in users(:user_two)

    assert_no_difference('Chapter.count') do
      post chapters_url, params: {
        chapter: chapter_params(number: 94, title: 'Missing team chapter').except(:scanlator_ids)
      }
    end

    assert_redirected_to root_path
  end

  test 'user without scanlator cannot get new chapter form' do
    sign_in User.find(101)

    get new_chapter_url(fiction: fictions(:one).slug)

    assert_redirected_to new_scanlator_path
  end

  test 'user without scanlator cannot create chapter' do
    sign_in User.find(101)

    assert_no_difference('Chapter.count') do
      post chapters_url, params: {
        chapter: chapter_params(number: 98, scanlator_ids: [scanlators(:one).id], title: 'No team chapter')
      }
    end

    assert_redirected_to new_scanlator_path
  end
end
