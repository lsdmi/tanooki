# frozen_string_literal: true

require 'test_helper'

module Chapters
  class SyncImagesTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_one)
      @chapter = chapters(:one)
      @first = store_chapter_image
      @second = store_chapter_image
    end

    test 'saving a chapter attaches the stored images its body links to' do
      save_chapter(body_with(@first, @second))

      assert_equal [@first.id, @second.id].sort, @chapter.images_attachments.pluck(:blob_id).sort
    end

    test 'removing an image from the body detaches it but keeps the blob for other chapters' do
      save_chapter(body_with(@first, @second))
      save_chapter(body_with(@second))

      assert_equal [@second.id], @chapter.images_attachments.pluck(:blob_id)
      assert ActiveStorage::Blob.exists?(@first.id)
    end

    test 'queues extraction when the saved body still has inline images' do
      assert_difference -> { extract_jobs.count } do
        save_chapter(%(<p>#{'x' * 500}<img src="data:image/png;base64,AAAA"></p>))
      end
      assert_equal [@chapter.id], extract_jobs.last.arguments['arguments']
    end

    test 'does not queue extraction when the body did not change' do
      save_chapter(%(<p>#{'x' * 500}<img src="data:image/png;base64,AAAA"></p>))

      assert_no_difference -> { extract_jobs.count } do
        Persist.call(chapter: @chapter.reload, attributes: { title: 'Only the title' }, intent: 'publish', user: @user)
      end
    end

    private

    def save_chapter(html)
      Persist.call(chapter: @chapter, attributes: { content: html }, intent: 'publish', user: @user)

      assert_empty @chapter.errors.full_messages
    end

    def body_with(*blobs)
      images = blobs.map { |blob| %(<img src="#{Images.url_for(blob)}">) }.join
      %(<p>#{'x' * 500}</p><p>#{images}</p>)
    end

    def extract_jobs
      SolidQueue::Job.where(class_name: 'Chapters::ExtractInlineImagesJob')
    end
  end
end
