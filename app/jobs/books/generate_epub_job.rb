# frozen_string_literal: true

module Books
  # Generates and attaches an EPUB file for a persisted export request.
  class GenerateEpubJob < ApplicationJob
    queue_as :default

    def perform(epub_export_request_id)
      export_request = EpubExportRequest.find_by(id: epub_export_request_id)
      return if export_request.nil? || export_request.expired?

      generate_epub(export_request)
    end

    private

    def generate_epub(export_request)
      export_request.processing!
      epub_export = Books::EpubExport.new(export_request.rich_text_ids, export_request.volume_title)
      epub_export.generate
      attach_epub(export_request, epub_export)
      export_request.update!(status: :ready, filename: epub_export.filename, error_message: nil)
    rescue StandardError => e
      export_request.update!(status: :failed, error_message: e.message)
    ensure
      file_path = epub_export&.file_path
      FileUtils.rm_f(file_path) if file_path.present?
    end

    def attach_epub(export_request, epub_export)
      File.open(epub_export.file_path, 'rb') do |file|
        export_request.file.attach(
          io: file,
          filename: epub_export.filename,
          content_type: 'application/epub+zip'
        )
      end
    end
  end
end
