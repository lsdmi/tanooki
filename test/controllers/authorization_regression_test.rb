# frozen_string_literal: true

require 'test_helper'

# Cross-cutting authorization smoke tests for high-risk mutations.
class AuthorizationRegressionTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'guest cannot create comments' do
    publication = publications(:tale_approved_one)

    assert_no_difference('Comment.count') do
      post comments_url(format: :turbo), params: {
        comment: { content: 'Guest comment', commentable_id: publication.id, commentable_type: Tale }
      }
    end

    assert_response :unauthorized
  end

  test 'guest cannot catch pokemon' do
    assert_no_difference('UserPokemon.count') do
      post catch_pokemon_path, params: { user_pokemon: { pokemon_id: 1 } }
    end

    assert_redirected_to new_user_session_path
  end

  test 'guest cannot start pokemon battle' do
    post battle_start_path, params: { defender: users(:user_one).id }

    assert_redirected_to new_user_session_path
  end

  test 'user cannot catch pokemon for another account' do
    sign_in users(:user_one)
    other_user = users(:user_two)
    UserPokemon.where(user_id: [users(:user_one).id, other_user.id], pokemon_id: 2).destroy_all

    assert_difference -> { users(:user_one).user_pokemons.reload.count }, 1 do
      post catch_pokemon_path, params: {
        user_pokemon: { pokemon_id: 2, user_id: other_user.id }
      }
    end

    assert_not UserPokemon.exists?(user_id: other_user.id, pokemon_id: 2)
  end

  test 'user without scanlator cannot create fiction' do
    sign_in User.find(101) # users fixture user_101: no scanlator membership

    assert_no_difference('Fiction.count') do
      get new_fiction_url
    end

    assert_redirected_to new_scanlator_path
  end

  test 'user outside fiction team cannot edit fiction' do
    sign_in users(:user_two)

    get edit_fiction_url(fictions(:one))

    assert_redirected_to root_path
  end

  test 'user outside fiction team cannot destroy fiction' do
    sign_in users(:user_two)

    assert_no_difference('Fiction.count') do
      delete fiction_url(fictions(:one))
    end

    assert_redirected_to root_path
  end

  test 'guest cannot create chapter' do
    assert_no_difference('Chapter.count') do
      post chapters_url, params: {
        chapter: {
          content: 'x' * 500,
          fiction_id: fictions(:one).id,
          number: 99,
          scanlator_ids: [scanlators(:one).id],
          title: 'Guest chapter'
        }
      }
    end

    assert_redirected_to new_user_session_path
  end

  test 'non-owner cannot update translation request' do
    sign_in users(:user_two)
    request = translation_requests(:one)

    patch translation_request_url(request), params: {
      translation_request: { title: 'Hijacked title' }
    }

    assert_response :forbidden
  end

  test 'guest cannot download epub export' do
    rich_text = ActionText::RichText.find_by(record: chapters(:one), name: 'content')

    get epub_download_path(id: rich_text), headers: { 'Accept' => 'application/json' }

    assert_response :unauthorized
  end

  test 'library rejects invalid reading status updates' do
    sign_in users(:user_one)
    reading_progress = reading_progresses(:one)
    reading_progress.update!(status: :active)

    patch update_reading_progress_path(reading_progress), params: { status: :invalid, current_section: :active }

    assert_equal 'active', reading_progress.reload.status
    assert_includes response.body, I18n.t('reading_progress.alerts.invalid_status')
  end
end
