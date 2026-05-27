# frozen_string_literal: true

require 'test_helper'

class ScanlatorsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'should get index as admin' do
    sign_in users(:user_one)
    get scanlators_path

    assert_response :redirect
    assert_redirected_to studio_index_path
  end

  test 'should get index as non-admin user' do
    sign_in users(:user_two)
    get scanlators_path

    assert_response :redirect
    assert_redirected_to studio_index_path
  end

  test 'should get new' do
    sign_in users(:user_one)
    get new_scanlator_url

    assert_response :success
  end

  test 'should create scanlator' do
    sign_in users(:user_one)
    assert_difference('Scanlator.count') do
      post scanlators_url, params: {
        scanlator: {
          avatar: Rack::Test::UploadedFile.new(Rails.root.join('app/assets/images/logo-default.svg'),
                                               'image/svg'),
          banner: Rack::Test::UploadedFile.new(Rails.root.join('app/assets/images/logo-default.svg'),
                                               'image/svg'),
          member_ids: [users(:user_one).id],
          title: 'New Scanlator'
        }
      }
    end

    assert_redirected_to scanlator_path(Scanlator.last)
  end

  test 'should not create scanlator with invalid data' do
    sign_in users(:user_one)
    assert_no_difference('Scanlator.count') do
      post scanlators_url, params: {
        scanlator: {
          avatar: nil,
          banner: nil,
          title: nil
        }
      }
    end

    assert_response :unprocessable_content
    assert_template 'new'
  end

  test 'should update scanlator' do
    sign_in users(:user_one)
    scanlator = scanlators(:one)

    patch scanlator_url(scanlator), params: {
      scanlator: {
        member_ids: [users(:user_one).id],
        title: 'Updated Scanlator'
      }
    }

    assert_redirected_to scanlator_path(scanlator)
    assert_equal 'Updated Scanlator', scanlator.reload.title
  end

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

  test 'should show scanlator' do
    scanlator = scanlators(:one)
    get scanlator_path(scanlator)

    assert_response :success
    assert_not_nil assigns(:fictions)
  end

  test 'should destroy scanlator' do
    sign_in users(:user_one)
    scanlator = scanlators(:two)

    assert_difference('Scanlator.count', -1) do
      delete scanlator_path(scanlator, format: :turbo)
    end
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
