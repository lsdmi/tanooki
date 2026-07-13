# frozen_string_literal: true

require 'test_helper'

class FictionsControllerCoverValidationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include CoverUploadHelper

  setup do
    sign_in users(:user_one)
    @fiction = fictions(:one)
  end

  test 'should not create fiction with invalid cover' do
    assert_no_difference('Fiction.count') do
      post fictions_url, params: {
        fiction: {
          title: 'New Fiction',
          author: 'New Author',
          description: 'a' * 50,
          cover: Rack::Test::UploadedFile.new(
            Rails.root.join('app/assets/images/logo-default.svg'),
            'image/svg'
          ),
          scanlator_ids: [1],
          status: :announced,
          user_id: @fiction.user_id
        }
      }
    end

    assert_response :unprocessable_content
    assert_includes response.body, 'Обкладинка має бути WebP, AVIF, JPEG або PNG.'
  end

  test 'should update fiction with valid cover' do
    patch fiction_url(@fiction), params: {
      fiction: {
        cover: valid_cover_upload,
        scanlator_ids: [1],
        title: 'Updated With Cover'
      }
    }

    assert_redirected_to fiction_path(@fiction)
    @fiction.reload

    assert_equal 'Updated With Cover', @fiction.title
    assert_equal 'image/webp', @fiction.cover.blob.content_type
  end

  test 'should update fiction with png cover stored as webp' do
    skip 'libvips not installed' unless Attachments::VariantProcessing.available?

    patch fiction_url(@fiction), params: {
      fiction: {
        cover: valid_png_cover_upload,
        scanlator_ids: [1],
        title: 'Updated With PNG Cover'
      }
    }

    assert_redirected_to fiction_path(@fiction)
    @fiction.reload

    assert_equal 'Updated With PNG Cover', @fiction.title
    assert_equal 'image/webp', @fiction.cover.blob.content_type
  end

  test 'should not update fiction with invalid cover' do
    patch fiction_url(@fiction), params: {
      fiction: {
        cover: Rack::Test::UploadedFile.new(
          Rails.root.join('app/assets/images/logo-default.svg'),
          'image/svg'
        ),
        scanlator_ids: [1],
        title: 'Should Not Save'
      }
    }

    assert_response :unprocessable_content
    @fiction.reload

    assert_not_equal 'Should Not Save', @fiction.title
  end
end
