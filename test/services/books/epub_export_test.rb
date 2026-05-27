# frozen_string_literal: true

require 'test_helper'

module Books
  class EpubExportTest < ActiveSupport::TestCase
    def setup
      @rich_text_ids = [3]
      @volume_title = 'Volume 1'
      @epub_export = EpubExport.new(@rich_text_ids, @volume_title)
    end

    test 'should initialize with correct attributes' do
      assert_equal @rich_text_ids, @epub_export.instance_variable_get(:@rich_texts).pluck(:id)
      assert_equal @volume_title, @epub_export.instance_variable_get(:@volume_title)
      assert_match(%r{\A.*tmp/epub_export_.*\.epub\z}, @epub_export.file_path)
    end

    test 'uses export request id in temp path when provided' do
      export = EpubExport.new(@rich_text_ids, @volume_title, export_request_id: 42)

      assert_includes export.file_path, 'epub_export_42.epub'
    end

    test 'should generate epub file' do
      @epub_export.generate

      assert_path_exists @epub_export.file_path
    end
  end
end
