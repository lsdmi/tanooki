# frozen_string_literal: true

require 'test_helper'

# Tags are edited by the same people who may edit genres: admins and members of the fiction's team.
class FictionsControllerTagsPermissionsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @fiction = fictions(:one)
    @user = users(:user_two)
  end

  test 'a user outside the team cannot change tags' do
    sign_in @user

    assert_no_difference ['FictionTag.count', 'FictionTagLink.count'] do
      patch fiction_url(@fiction), params: { fiction: { tag_names: ['Чужий теґ'] } }
    end

    assert_redirected_to root_url
  end

  test 'a team member can change tags' do
    ScanlatorUser.create!(user: @user, scanlator: scanlators(:one))
    sign_in @user

    patch fiction_url(@fiction), params: { fiction: { scanlator_ids: [1], tag_names: ['ЛітРПГ'] } }

    assert_equal ['ЛітРПГ'], @fiction.fiction_tags.pluck(:name)
  end
end
