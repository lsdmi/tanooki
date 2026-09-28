# frozen_string_literal: true

require 'test_helper'

module Chapters
  class ExtractBackfillTest < ActiveSupport::TestCase
    setup do
      @chapter = chapters(:one)
      @rich_text = @chapter.rich_text_content
      @image = Base64.strict_encode64(File.binread(CoverUploadHelper::VALID_COVER_PATH))
    end

    test 'moves inline images out of a live chapter body' do
      write_inline_body

      result = backfill

      assert_equal [1, 1, 1], [result.candidates, result.extracted, result.images]
      assert_operator result.after_bytes, :<, result.before_bytes
      assert_not_includes raw_body, 'base64,'
    end

    test 'ignores bodies without inline images' do
      @rich_text.update!(body: '<p>no images</p>')

      assert_equal 0, backfill.candidates
    end

    test 'includes soft-deleted chapters and their soft-deleted bodies' do
      write_inline_body
      @chapter.destroy!

      assert_equal [1, 1], [backfill.candidates, Chapter.with_deleted.find(@chapter.id).images.count]
      assert_not_includes raw_body, 'base64,'
    end

    test 'skips bodies over max_body_bytes' do
      write_inline_body

      result = backfill(max_body_bytes: 1.kilobyte)

      assert_equal [@chapter.id], result.skipped.pluck(:chapter_id)
      assert_equal 0, result.extracted
    end

    test 'skips bodies under min_body_bytes' do
      write_inline_body

      assert_equal 1, backfill(min_body_bytes: 10.megabytes).skipped.size
    end

    test 'dry run finds candidates without rewriting them' do
      write_inline_body
      before = raw_body

      result = backfill(dry_run: true)

      assert_equal [1, 0], [result.candidates, result.extracted]
      assert_equal before, raw_body
    end

    test 'an unreadable image stays inline and counts as failed, not rewritten' do
      write_body('<p><img src="data:image/png;base64,bm90IGFuIGltYWdl"></p>')

      result = backfill

      assert_equal [1, 1, 0], [result.unchanged, result.failed_images, result.before_bytes]
    end

    test 'local pass walks every window until done' do
      half = (ActionText::RichText.unscoped.maximum(:id) / 2) + 1
      windows = []
      last = ExtractBackfill.run_local(after_id: 0, min_body_bytes: 16.megabytes, scan_size: half, pause: 0) do |r|
        windows << r.to_id
      end

      assert last.done
      assert_equal [half, half * 2], windows
    end

    test 'reports done once the window reaches the last rich text id' do
      last_id = ActionText::RichText.unscoped.maximum(:id)

      assert ExtractBackfill.call(after_id: last_id - 1, scan_size: 1).done
      assert_not ExtractBackfill.call(after_id: 0, scan_size: 1).done if last_id > 1
    end

    private

    def backfill(**)
      ExtractBackfill.call(after_id: @rich_text.id - 1, scan_size: 1, **)
    end

    def write_inline_body
      write_body(%(<p>Text</p><p><img src="data:image/webp;base64,#{@image}"></p>))
    end

    def write_body(html)
      travel_to(1.hour.ago) { @rich_text.update!(body: html) }
    end

    def raw_body
      @rich_text.reload.read_attribute_before_type_cast(:body)
    end
  end
end
