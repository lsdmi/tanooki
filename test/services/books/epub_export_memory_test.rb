# frozen_string_literal: true

require 'test_helper'

module Books
  class EpubExportMemoryTest < ActiveSupport::TestCase
    # Returns the given RSS readings in order, then repeats the last one.
    class FakeMemory
      def initialize(*readings)
        @readings = readings
        @reads = Thread::Queue.new
      end

      def rss_mb
        reading = @readings.size > 1 ? @readings.shift : @readings.first
        @reads << reading
        reading
      end

      def wait_for_reads(count)
        count.times { @reads.pop(timeout: 2) }
      end
    end

    setup do
      @log = StringIO.new
      @export_request = EpubExportRequest.new(id: 42, rich_text_ids: [1, 2, 3])
      @epub = Tempfile.new(['memory', '.epub'])
      @epub.write('x' * 2.megabytes)
      @epub.flush
    end

    teardown { @epub.close! }

    test 'logs and keeps RSS before, the sampled peak and after one build' do
      memory = FakeMemory.new(400, 520, 470)
      result = measure(memory) do
        memory.wait_for_reads(3)
        Struct.new(:file_path).new(@epub.path)
      end

      assert_equal @epub.path, result.file_path
      assert_match(/request=42 chapters=3 source=\S+ epub=2.0MB rss_before=400MB peak=520MB rss_after=470MB/,
                   @log.string)
      assert_equal [42, 3, 2.megabytes, 400, 520, 470],
                   EpubExportStat.last.values_at(:epub_export_request_id, :chapters, :epub_bytes, :rss_before_mb,
                                                 :rss_peak_mb, :rss_after_mb)
    end

    test 'keeps a failed build without an EPUB size and re-raises its error' do
      assert_raises(RuntimeError) { measure(FakeMemory.new(400, 410)) { raise 'boom' } }

      assert_includes @log.string, 'epub=- rss_before=400MB peak=410MB rss_after=410MB'
      assert_equal [nil, 410], EpubExportStat.last.values_at(:epub_bytes, :rss_peak_mb)
    end

    test 'a failed write is logged and the build result still returned' do
      result = EpubExportStat.stub(:create!, ->(*) { raise ActiveRecord::ConnectionNotEstablished }) do
        measure(FakeMemory.new(400)) { Struct.new(:file_path).new(@epub.path) }
      end

      assert_equal @epub.path, result.file_path
      assert_includes @log.string, 'request=42 record failed: ActiveRecord::ConnectionNotEstablished'
    end

    test 'records nothing where RSS cannot be read' do
      assert_no_difference('EpubExportStat.count') do
        assert_equal :built, measure(FakeMemory.new(nil)) { :built }
      end
      assert_empty @log.string
    end

    private

    def measure(memory, &)
      EpubExportMemory.new(@export_request, memory:, logger: Logger.new(@log), sample_every: 0.01).measure(&)
    end
  end
end
