# frozen_string_literal: true

require 'test_helper'

class PublicationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @publication = publications(:tale_approved_one)

    user = users(:user_one)
    host! 'localhost:3000'
    sign_in user
    @publication_params = {
      cover: Rack::Test::UploadedFile.new(
        Rails.root.join('app', 'assets', 'images', 'logo.svg'),
        'image/svg'
      ),
      description: action_text_rich_texts(:rich_text_one),
      highlight: @publication.highlight,
      status: @publication.status,
      status_message: @publication.status_message,
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

    assert_redirected_to root_path
  end
end
