# frozen_string_literal: true

module Books
  # Persists EPUB export progress without relying on a stale ActiveRecord instance.
  module EpubExportProgress
    module_function

    def update!(export_request_id, step)
      return unless export_request_id

      export = EpubExportRequest.find_by(id: export_request_id)
      return unless export

      export.update!(processing_step: step)
      Rails.logger.info("[EPUB export #{export_request_id}] #{step}")
    end
  end
end
