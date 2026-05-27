# frozen_string_literal: true

module Books
  # Generates and attaches an EPUB file for a persisted export request.
  class GenerateEpubJob < ApplicationJob
    queue_as :default

    def perform(epub_export_request_id)
      export_request = EpubExportRequest.find_by(id: epub_export_request_id)
      return if export_request.nil? || export_request.expired? || export_request.ready?

      generate_epub(export_request)
    end

    private

    def generate_epub(export_request)
      epub_export = nil
      export_request.processing!
      epub_export = build_epub_export(export_request)
      mark_export_ready(export_request, epub_export)
    rescue StandardError => e
      export_request.update!(status: :failed, error_message: export_error_message(e))
    ensure
      cleanup_epub_export(epub_export)
    end

    def build_epub_export(export_request)
      Books::EpubExport.new(
        export_request.rich_text_ids,
        export_request.volume_title,
        export_request_id: export_request.id
      ).tap(&:generate)
    end

    def mark_export_ready(export_request, epub_export)
      attach_epub(export_request, epub_export)
      export_request.update!(status: :ready, filename: epub_export.filename, error_message: nil)
    end

    def cleanup_epub_export(epub_export)
      file_path = epub_export&.file_path
      FileUtils.rm_f(file_path) if file_path.present?
    end

    def attach_epub(export_request, epub_export)
      bytes = File.binread(epub_export.file_path)
      export_request.file.purge if export_request.file.attached?

      export_request.file.attach(
        io: StringIO.new(bytes),
        filename: epub_export.filename,
        content_type: 'application/epub+zip',
        identify: false
      )
    end

    def export_error_message(error)
      return I18n.t('downloads.epub_export.storage_integrity_error') if error.is_a?(ActiveStorage::IntegrityError)

      [error.class.name, error.message].join(': ')
    end
  end
end
