# frozen_string_literal: true

require 'test_helper'

class ScanlatorsMembershipControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'team member can add members' do
    sign_in users(:user_two)
    scanlator = scanlators(:two)

    patch scanlator_url(scanlator), params: {
      scanlator: {
        avatar: uploaded_svg,
        banner: uploaded_svg,
        member_ids: [users(:user_one).id, users(:user_two).id],
        title: scanlator.title
      }
    }

    assert_redirected_to scanlator_path(scanlator)
    assert_equal [users(:user_one).id, users(:user_two).id].sort, scanlator.reload.users.ids.sort
  end

  test 'non-admin create adds selected members and always includes creator' do
    sign_in users(:user_two)

    assert_difference('Scanlator.count') do
      post scanlators_url, params: {
        scanlator: {
          avatar: uploaded_svg,
          banner: uploaded_svg,
          member_ids: [users(:user_one).id],
          title: 'New Team'
        }
      }
    end

    team = Scanlator.find_by(title: 'New Team')

    assert_equal [users(:user_one).id, users(:user_two).id].sort, team.users.ids.sort
  end

  test 'non-admin should update own scanlator' do
    sign_in users(:user_two)
    scanlator = scanlators(:two)

    patch scanlator_url(scanlator), params: {
      scanlator: {
        avatar: uploaded_svg,
        banner: uploaded_svg,
        member_ids: [users(:user_two).id],
        title: 'Updated Own Scanlator'
      }
    }

    assert_redirected_to scanlator_path(scanlator)
    assert_equal 'Updated Own Scanlator', scanlator.reload.title
  end

  test 'non-admin should destroy own scanlator' do
    sign_in users(:user_two)

    assert_difference('Scanlator.count', -1) do
      delete scanlator_path(scanlators(:two), format: :turbo)
    end
  end

  private

  def uploaded_svg
    Rack::Test::UploadedFile.new(Rails.root.join('app/assets/images/logo-default.svg'), 'image/svg+xml')
  end
end
