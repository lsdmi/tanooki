# frozen_string_literal: true

require 'test_helper'

module Books
  class GenerateEpubJobTest < ActiveSupport::TestCase
    def setup
      @rich_text = action_text_rich_texts(:rich_text_four)
      @export_request = EpubExportRequest.create!(user: users(:user_one), rich_text_ids: [@rich_text.id])
      @dummy_file_path = Rails.root.join('tmp/generated_book.epub')
      FileUtils.touch(@dummy_file_path)
    end

    test 'perform marks request ready with generated filename' do
      run_successful_export
      @export_request.reload

      assert_predicate @export_request, :ready?
      assert_equal 'generated_book.epub', @export_request.filename
    end

    test 'perform attaches generated epub and removes temporary file' do
      run_successful_export
      @export_request.reload

      assert_predicate @export_request.file, :attached?
      refute_path_exists @dummy_file_path
    end

    test 'perform marks request failed when generation raises' do
      EpubExport.stub(:new, ->(*) { raise StandardError, 'boom' }) do
        GenerateEpubJob.perform_now(@export_request.id)
      end

      @export_request.reload

      assert_predicate @export_request, :failed?
      assert_equal 'StandardError: boom', @export_request.error_message
    end

    test 'perform skips already ready exports' do
      @export_request.update!(status: :ready, filename: 'existing.epub')
      attach_dummy_epub(@export_request)

      EpubExport.stub(:new, ->(*) { flunk 'should not regenerate' }) do
        GenerateEpubJob.perform_now(@export_request.id)
      end

      assert_predicate @export_request.reload, :ready?
    end

    test 'perform marks request failed with friendly message on storage integrity error' do
      job = GenerateEpubJob.new
      job.define_singleton_method(:attach_epub) { |*, **| raise ActiveStorage::IntegrityError }

      EpubExport.stub(:new, fake_epub_export) do
        job.perform(@export_request.id)
      end

      @export_request.reload

      assert_predicate @export_request, :failed?
      assert_equal I18n.t('downloads.epub_export.storage_integrity_error'), @export_request.error_message
    end

    private

    def run_successful_export
      EpubExport.stub(:new, fake_epub_export) do
        GenerateEpubJob.perform_now(@export_request.id)
      end
    end

    def fake_epub_export
      Struct.new(:file_path, :filename) do
        def generate
          self
        end
      end.new(@dummy_file_path.to_s, 'generated_book.epub')
    end

    def attach_dummy_epub(export_request)
      File.binread(@dummy_file_path)
      export_request.file.attach(
        io: StringIO.new(File.binread(@dummy_file_path)),
        filename: 'generated_book.epub',
        content_type: 'application/epub+zip',
        identify: false
      )
    end

  end
end
