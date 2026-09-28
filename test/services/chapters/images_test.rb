# frozen_string_literal: true

require 'test_helper'

module Chapters
  class ImagesTest < ActiveSupport::TestCase
    setup do
      @blob = store_chapter_image
    end

    test 'stores on the chapter image service without queuing analysis' do
      assert_equal 'test_chapter_images', @blob.service_name
      assert_predicate @blob, :analyzed?
      assert @blob.service.exist?(@blob.key)
    end

    test 'links the redirect path outside production and finds the blob from it' do
      url = Images.url_for(@blob)

      assert url.start_with?('/rails/active_storage/blobs/')
      assert_equal [@blob], Images.blobs_in(%(<p><img alt="a" src="#{url}"></p>)).to_a
      assert_equal @blob, Images.blob_for_url("http://localhost:3000#{url}")
    end

    test 'links the CDN URL when a CDN host is set and finds the blob from its key' do
      with_cdn_host('https://cdn.example.com') do
        url = Images.url_for(@blob)

        assert_equal "https://cdn.example.com/#{@blob.key}", url
        assert_equal [@blob], Images.blobs_in(%(<img src='#{url}'>)).to_a
      end
    end

    test 'ignores external images, inline images and blobs of other services' do
      cover = ActiveStorage::Blob.create_and_upload!(io: StringIO.new('x'), filename: 'c.webp', service_name: 'test')
      html = <<~HTML
        <img src="https://example.com/a.png">
        <img src="data:image/png;base64,AAAA">
        <img src="#{Rails.application.routes.url_helpers.rails_blob_path(cover, only_path: true)}">
      HTML

      assert_empty Images.blobs_in(html)
    end

    private

    def with_cdn_host(host)
      config = Rails.configuration.x.chapter_images
      previous = config.cdn_host
      config.cdn_host = host
      yield
    ensure
      config.cdn_host = previous
    end
  end
end
