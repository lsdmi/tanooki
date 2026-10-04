# frozen_string_literal: true

require 'test_helper'

module Books
  class EpubExportMemoryTest < ActiveSupport::TestCase
    FakeMemory = Struct.new(:rss_values, :peak, :resettable) do
      def rss_mb = rss_values.shift
      def peak_rss_mb = peak
      def reset_peak_rss = resettable
    end

    setup do
      @log = StringIO.new
      @export_request = EpubExportRequest.new(id: 42, rich_text_ids: [1, 2, 3])
      @epub = Tempfile.new(['memory', '.epub'])
      @epub.write('x' * 2.megabytes)
      @epub.flush
    end

    teardown { @epub.close! }

    test 'logs RSS before, peak and after one build' do
      result = measure(FakeMemory.new([400, 470], 520, true)) { Struct.new(:file_path).new(@epub.path) }

      assert_equal @epub.path, result.file_path
      assert_match(/request=42 chapters=3 source=\S+ epub=2.0MB rss_before=400MB peak=520MB rss_after=470MB/,
                   @log.string)
    end

    test 'logs a failed build and re-raises its error' do
      assert_raises(RuntimeError) { measure(FakeMemory.new([400, 410], 450, false)) { raise 'boom' } }

      assert_includes @log.string, 'epub=- rss_before=400MB peak=- rss_after=410MB'
    end

    test 'logs nothing where RSS cannot be read' do
      assert_equal :built, measure(FakeMemory.new([nil], nil, false)) { :built }
      assert_empty @log.string
    end

    private

    def measure(memory, &)
      EpubExportMemory.new(@export_request, memory:, logger: Logger.new(@log)).measure(&)
    end
  end
end
