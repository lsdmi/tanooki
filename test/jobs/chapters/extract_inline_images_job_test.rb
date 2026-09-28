# frozen_string_literal: true

require 'test_helper'

module Chapters
  class ExtractInlineImagesJobTest < ActiveSupport::TestCase
    test 'runs on the heavy queue' do
      assert_equal "#{Rails.env}_heavy", ExtractInlineImagesJob.new.queue_name
    end

    test 'extracts the chapter images' do
      chapter = chapters(:one)
      called_with = nil
      fake = lambda do |id|
        called_with = id
        ExtractInlineImages::Result.new(status: :extracted, extracted: 1, failed: 0, before_bytes: 10, after_bytes: 5)
      end

      ExtractInlineImages.stub(:call, fake) { ExtractInlineImagesJob.perform_now(chapter.id) }

      assert_equal chapter.id, called_with
    end

    test 'skips bodies too large for the worker' do
      chapter = chapters(:one)
      ActionText::RichText.lease_connection.update(
        "UPDATE action_text_rich_texts SET body = REPEAT('x', #{ExtractInlineImagesJob::MAX_BODY_BYTES + 1}) " \
        "WHERE id = #{chapter.rich_text_content.id}"
      )

      ExtractInlineImages.stub(:call, ->(_) { flunk 'must not load an oversized body' }) do
        assert_nil ExtractInlineImagesJob.perform_now(chapter.id)
      end
    end

    test 'drops the job when the chapter is gone' do
      chapter = chapters(:one)
      chapter.destroy!

      assert_nothing_raised { ExtractInlineImagesJob.perform_now(chapter.id) }
    end
  end
end
