# frozen_string_literal: true

require 'test_helper'

class PublicationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @publication = publications(:tale_approved_one)

    user = users(:user_one)
    sign_in user
    @publication_params = {
      cover: Rack::Test::UploadedFile.new(
        Rails.root.join('app', 'assets', 'images', 'logo.svg'),
        'image/svg'
      ),
      description: action_text_rich_texts(:rich_text_one),
      highlight: @publication.highlight,
      title: @publication.title,
      type: @publication.type,
      user_id: @publication.user_id
    }
  end

  test 'should create publication' do
    assert_difference('Publication.count') do
      post publications_url, params: { publication: @publication_params }
    end

    assert_redirected_to root_path
  end

  test 'should update publication' do
    patch publication_url(@publication), params: { publication: @publication_params }
    assert_redirected_to tale_path(@publication)
  end

  test 'should destroy publication' do
    assert_difference('Publication.count', -1) do
      delete publication_url(@publication)
    end

    assert_response :success
    assert_template 'users/dashboard/_publications'
    assert_template '_publications'
  end

  test 'should update publication with tags' do
    tag_ids = Tag.all.sample(2).map(&:id)
    patch publication_url(@publication), params: { publication: { tag_ids: } }
    assert_redirected_to tale_path(@publication)
    assert_equal tag_ids.sort, @publication.tags.ids.sort
  end

  test 'should get new' do
    get new_publication_path
    assert_response :success
  end

  test 'should get edit' do
    get edit_publication_path(Tale.first)
    assert_response :success
  end

  test 'publications should return all publications for admin users' do
    request = ActionController::TestRequest.new({}, nil, :get)
    request.env['HTTP_REFERER'] = 'http://localhost:3000/admin/tales'

    @controller = PublicationsController.new
    @controller.stub :request, request do
      assert_equal Publication.all.order(created_at: :desc), @controller.send(:publications)
    end
  end

  test "publications should return current user's publications for non-admin users" do
    request = ActionController::TestRequest.new({}, nil, :get)
    request.env['HTTP_REFERER'] = 'http://localhost:3000/admin/dashboard'

    new_user = users(:user_two)

    @controller = PublicationsController.new
    @controller.stub :request, request do
      @controller.stub :current_user, new_user do
        assert_equal new_user.publications.order(created_at: :desc), @controller.send(:publications)
      end
    end
  end

  test 'request_path should return admin tales path for admin users' do
    request = ActionController::TestRequest.new({}, nil, :get)
    request.env['HTTP_REFERER'] = 'http://localhost:3000/admin/tales'

    @controller = PublicationsController.new
    @controller.stub :request, request do
      assert_equal '/admin/tales', @controller.send(:request_path)
    end
  end

  test 'request_path should return dashboard path for non-admin users' do
    request = ActionController::TestRequest.new({}, nil, :get)
    request.env['HTTP_REFERER'] = 'http://localhost:3000/dashboard'

    @controller = PublicationsController.new
    @controller.stub :request, request do
      assert_equal '/dashboard', @controller.send(:request_path)
    end
  end

  test 'verify_permissions should allow access for admin users' do
    get edit_publication_path(@publication)
    assert_response :success
  end

  test "verify_permissions should allow access for publication's owner" do
    sign_in @publication.user
    get edit_publication_path(@publication)
    assert_response :success
  end

  test 'verify_permissions should redirect to root path for non-admin users without permission' do
    sign_in users(:user_two)
    get edit_publication_path(@publication)
    assert_redirected_to root_path
  end
end
