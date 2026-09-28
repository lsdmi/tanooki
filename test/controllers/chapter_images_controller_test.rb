# frozen_string_literal: true

require 'test_helper'

class ChapterImagesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    ActionController::Base.cache_store.clear
    @member = users(:user_two)
  end

  test 'a team member uploads an image and gets a link to an unattached chapter image blob' do
    sign_in @member

    assert_difference -> { ActiveStorage::Blob.where(service_name: Chapters::Images.service_name).count } do
      post chapter_images_url, params: { file: valid_cover_upload }, as: :multipart_form
    end

    blob = ActiveStorage::Blob.order(:id).last

    assert_equal Chapters::Images.url_for(blob), response.parsed_body['location']
    assert_empty blob.attachments
  end

  test 'a user with no team cannot upload' do
    user = users('user_101')
    user.scanlator_users.delete_all
    sign_in user

    post chapter_images_url, params: { file: valid_cover_upload }

    assert_response :forbidden
    assert_predicate response.parsed_body['error'], :present?
  end

  test 'guests are turned away' do
    post chapter_images_url, params: { file: valid_cover_upload }, headers: { 'Accept' => 'application/json' }

    assert_response :unauthorized
  end

  test 'rejects a file that is not an image' do
    sign_in @member
    file = Rack::Test::UploadedFile.new(StringIO.new('not an image'), 'image/png', original_filename: 'fake.png')

    assert_no_difference -> { ActiveStorage::Blob.count } do
      post chapter_images_url, params: { file: }
    end

    assert_response :unprocessable_content
  end

  test 'rejects a missing file' do
    sign_in @member

    post chapter_images_url

    assert_response :unprocessable_content
  end

  test 'rejects files over the upload limit before processing them' do
    sign_in @member
    path = Rails.root.join('tmp/chapter_image_too_large.bin')
    File.open(path, 'wb') { |file| file.truncate(ChapterImagesController::MAX_UPLOAD_BYTES + 1) }

    Chapters::ImageProcessor.stub(:call, ->(_) { flunk 'must not process oversized uploads' }) do
      post chapter_images_url, params: { file: Rack::Test::UploadedFile.new(path, 'image/jpeg') }
    end

    assert_response :content_too_large
  ensure
    FileUtils.rm_f(path)
  end

  test 'rate limits uploads per user' do
    sign_in @member

    120.times { post chapter_images_url }
    post chapter_images_url

    assert_response :too_many_requests
    assert_predicate response.parsed_body['error'], :present?
  end
end
