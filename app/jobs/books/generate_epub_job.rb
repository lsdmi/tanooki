# frozen_string_literal: true

module Books
  # Generates and attaches an EPUB file for a persisted export request.
  class GenerateEpubJob < ApplicationJob
    queue_as :epub

    after_discard do |job, error|
      export_request = EpubExportRequest.find_by(id: job.arguments.first)
      next unless export_request
      next if export_request.ready?

      export_request.update!(
        status: :failed,
        error_message: Books::GenerateEpubJob.export_error_message(error),
        processing_step: nil
      )
    end

    def perform(epub_export_request_id)
      export_request = EpubExportRequest.find_by(id: epub_export_request_id)
      return if export_request.nil? || export_request.expired? || export_request.ready?

      return fail_missing_vips_export(export_request) if missing_vips_for_export?(export_request)

      generate_epub(export_request)
    end

    def self.export_error_message(error)
      new.send(:export_error_message, error)
    end

    private

    def generate_epub(export_request)
      epub_export = nil
      export_request.update!(processing_step: 'starting')
      export_request.processing!
      EpubExportProgress.update!(export_request.id, 'building')
      epub_export = build_epub_export(export_request)
      mark_export_ready(export_request, epub_export)
    rescue StandardError => e
      export_request.update!(status: :failed, error_message: export_error_message(e), processing_step: nil)
    ensure
      cleanup_epub_export(epub_export)
    end

    def missing_vips_for_export?(export_request)
      Books::EpubExportLimits.blocked_by_missing_vips?(export_request.rich_text_ids)
    end

    def fail_missing_vips_export(export_request)
      export_request.update!(
        status: :failed,
        error_message: I18n.t('downloads.epub_export.image_processing_unavailable'),
        processing_step: nil
      )
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
      export_request.update!(status: :ready, filename: epub_export.filename, error_message: nil, processing_step: nil)
    end

    def cleanup_epub_export(epub_export)
      file_path = epub_export&.file_path
      FileUtils.rm_f(file_path) if file_path.present?
    end

    def attach_epub(export_request, epub_export)
      export_request.file.purge if export_request.file.attached?

      File.open(epub_export.file_path, 'rb') do |io|
        export_request.file.attach(
          io: io,
          filename: epub_export.filename,
          content_type: 'application/epub+zip',
          identify: false
        )
      end
    end

    def export_error_message(error)
      return I18n.t('downloads.epub_export.storage_integrity_error') if error.is_a?(ActiveStorage::IntegrityError)

      [error.class.name, error.message].join(': ')
    end
  end
end
