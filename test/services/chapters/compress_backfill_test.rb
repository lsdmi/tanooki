# frozen_string_literal: true

require 'test_helper'

module Chapters
  class CompressBackfillTest < ActiveSupport::TestCase
    setup do
      @chapter = chapters(:one)
      @rich_text = action_text_rich_texts(:rich_text_four)
      @jpeg = Base64.decode64(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='
      )
    end

    test 'compresses a live chapter body with an oversized inline image' do
      write_compressible_body

      result = with_compression_stub { backfill }

      assert_equal [1, 1], [result.candidates, result.compressed]
      assert_operator result.after_bytes, :<, result.before_bytes
      assert_operator @rich_text.reload.body.to_html.bytesize, :<, 100.kilobytes
    end

    test 'ignores bodies without inline images' do
      @rich_text.update!(body: '<p>no images</p>')

      assert_equal 0, backfill.candidates
    end

    test 'ignores soft-deleted chapters' do
      write_compressible_body
      @chapter.destroy!

      assert_equal 0, backfill.candidates
    end

    test 'skips bodies over max_body_bytes' do
      write_compressible_body

      result = with_compression_stub { backfill(max_body_bytes: 1.kilobyte) }

      assert_equal [@chapter.id], result.skipped.pluck(:chapter_id)
      assert_equal 0, result.compressed
    end

    test 'skips bodies under min_body_bytes' do
      write_compressible_body

      result = with_compression_stub { backfill(min_body_bytes: 10.megabytes) }

      assert_equal 1, result.skipped.size
    end

    test 'dry run finds candidates without rewriting them' do
      write_compressible_body
      before = @rich_text.reload.body.to_html

      result = with_compression_stub { backfill(dry_run: true) }

      assert_equal [1, 0], [result.candidates, result.compressed]
      assert_operator result.candidate_bytes, :>, 450.kilobytes
      assert_equal before, @rich_text.reload.body.to_html
    end

    test 'local pass walks every window until done' do
      half = (ActionText::RichText.unscoped.maximum(:id) / 2) + 1
      windows = []
      last = CompressBackfill.run_local(after_id: 0, min_body_bytes: 16.megabytes, scan_size: half, pause: 0) do |r|
        windows << r.to_id
      end

      assert last.done
      assert_equal [half, half * 2], windows
    end

    test 'counts bytes only for bodies it rewrites' do
      @rich_text.update!(body: %(<p><img src="data:image/png;base64,#{Base64.strict_encode64(@jpeg)}"></p>))

      result = with_compression_stub { backfill }

      assert_equal 1, result.unchanged
      assert_equal 0, result.before_bytes
      assert_operator result.candidate_bytes, :>, 0
    end

    test 'reports done once the window reaches the last rich text id' do
      last_id = ActionText::RichText.unscoped.maximum(:id)

      assert CompressBackfill.call(after_id: last_id - 1, scan_size: 1).done
      assert_not CompressBackfill.call(after_id: 0, scan_size: 1).done if last_id > 1
    end

    private

    def backfill(**)
      CompressBackfill.call(after_id: @rich_text.id - 1, scan_size: 1, **)
    end

    def write_compressible_body
      encoded = Base64.strict_encode64('x' * 450.kilobytes)
      @rich_text.update!(body: %(<p><img src="data:image/png;base64,#{encoded}"></p>))
    end

    def with_compression_stub(&)
      InlineImageOptimizer.stub(:optimize_data_uri_in_html, [@jpeg, 'jpg']) do
        Attachments::VariantProcessing.stub(:available?, true, &)
      end
    end
  end
end
