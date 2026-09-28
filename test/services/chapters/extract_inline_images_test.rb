# frozen_string_literal: true

require 'test_helper'

module Chapters
  class ExtractInlineImagesTest < ActiveSupport::TestCase
    setup do
      @chapter = chapters(:one)
      @rich_text = @chapter.rich_text_content
      @image = Base64.strict_encode64(File.binread(CoverUploadHelper::VALID_COVER_PATH))
    end

    test 'moves inline images into storage, links them and attaches them' do
      write_body(%(<p>Text</p><p><img alt="map" src="data:image/webp;base64,#{@image}"></p>))

      result = ExtractInlineImages.call(@chapter.id)
      body = raw_body
      blob = @chapter.images.blobs.sole

      assert_equal [:extracted, 1], [result.status, result.extracted]
      assert_includes body, %(<img alt="map" src="#{Images.url_for(blob)}">)
      assert_not_includes body, 'base64,'
    end

    test 'leaves an unreadable image inline and still moves the others' do
      write_body(%(<img src="data:image/png;base64,bm90IGFuIGltYWdl"><img src="data:image/webp;base64,#{@image}">))

      result = ExtractInlineImages.call(@chapter.id)

      assert_equal [:extracted, 1, 1], [result.status, result.extracted, result.failed]
      assert_includes raw_body, 'data:image/png;base64,bm90IGFuIGltYWdl'
    end

    test 'never overwrites an edit saved while it ran' do
      write_body(%(<img src="data:image/webp;base64,#{@image}">))
      process = ImageProcessor.method(:call)
      edit_mid_run = lambda do |path|
        ActionText::RichText.find(@rich_text.id).update!(body: '<p>user edit</p>')
        process.call(path)
      end

      result = ImageProcessor.stub(:call, edit_mid_run) { ExtractInlineImages.call(@chapter.id) }

      assert_equal :conflict, result.status
      assert_equal '<p>user edit</p>', raw_body
      assert_empty @chapter.images_attachments
    end

    test 'does nothing for a body without inline images' do
      write_body('<p>plain</p>')

      assert_equal :unchanged, ExtractInlineImages.call(@chapter.id).status
    end

    private

    def write_body(html)
      travel_to(1.hour.ago) { @rich_text.update!(body: html) }
    end

    def raw_body
      @rich_text.reload.read_attribute_before_type_cast(:body)
    end
  end
end
