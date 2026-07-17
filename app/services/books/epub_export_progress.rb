# frozen_string_literal: true

module Books
  # Persists EPUB export progress without relying on a stale ActiveRecord instance.
  module EpubExportProgress
    module_function

    def update!(export_request_id, step)
      return unless export_request_id

      # Intentionally bypasses validations/callbacks so progress survives stale AR instances.
      EpubExportRequest.where(id: export_request_id).update_all( # rubocop:disable Rails/SkipsModelValidations
        processing_step: step,
        updated_at: Time.current
      )
      Rails.logger.info("[EPUB export #{export_request_id}] #{step}")
    end
  end
end
