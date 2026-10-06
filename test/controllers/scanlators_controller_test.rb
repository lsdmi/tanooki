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
      post scanlators_url, params: { scanlator: new_scanlator_params }
    end

    assert_redirected_to scanlator_path(Scanlator.last)
  end

  test 'coming from a chapter form, new explains why a team is needed and keeps the way back' do
    sign_in User.find(101)
    get new_scanlator_url(return_to: '/chapters/new?fiction=one')

    assert_select '[role="note"]', text: /потрібна команда/
    assert_select 'input[type="hidden"][name="return_to"][value="/chapters/new?fiction=one"]'
  end

  test 'new ignores a return_to that is not a chapter form' do
    sign_in User.find(101)
    get new_scanlator_url(return_to: 'https://evil.example/chapters/new?fiction=one')

    assert_select 'input[name="return_to"]', count: 0
  end

  test 'create returns to the chapter form it came from' do
    sign_in User.find(101)
    post scanlators_url, params: { return_to: '/chapters/new?fiction=one',
                                   scanlator: new_scanlator_params(member_ids: [101]) }

    assert_redirected_to '/chapters/new?fiction=one'
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
  test 'should show scanlator' do
    scanlator = scanlators(:one)
    get scanlator_path(scanlator)

    assert_response :success
    assert_not_nil assigns(:fictions)
    assert_kind_of Scanlators::ShowPresenter, assigns(:scanlator_stats)
  end

  test 'should show scanlator stats on profile page' do
    get scanlator_path(scanlators(:one))

    assert_includes response.body, 'Розділів'
    assert_includes response.body, '4.5'
  end

  test 'should destroy scanlator' do
    sign_in users(:user_one)
    scanlator = scanlators(:two)

    assert_difference('Scanlator.count', -1) do
      delete scanlator_path(scanlator, format: :turbo_stream)
    end

    assert_response :success
    assert_turbo_stream_flash_notice(I18n.t('scanlators.notices.destroy_success'))
  end

  private

  def uploaded_svg
    Rack::Test::UploadedFile.new(Rails.root.join('app/assets/images/logo-default.svg'), 'image/svg+xml')
  end

  def new_scanlator_params(member_ids: [users(:user_one).id])
    { avatar: uploaded_svg, banner: uploaded_svg, member_ids:, title: 'New Scanlator' }
  end
end
