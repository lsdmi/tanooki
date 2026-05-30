# frozen_string_literal: true

# JSON response helpers for EPUB export enqueue and status endpoints.
module DownloadsEpubExportResponses
  extend ActiveSupport::Concern

  private

  def render_epub_enqueue_response(export_request, cached:)
    render json: epub_enqueue_payload(export_request, cached:),
           status: cached && export_request.ready? ? :ok : :accepted
  end

  def epub_enqueue_payload(export_request, cached:)
    epub_export_status_payload(export_request).merge(cached:)
  end

  def epub_export_status_payload(export_request)
    {
      status: epub_export_status_value(export_request),
      status_url: epub_export_status_path_for(export_request),
      download_url: epub_export_download_url(export_request),
      error_message: epub_export_error_message(export_request)
    }.compact
  end

  def epub_export_status_value(export_request)
    return 'expired' if export_request.expired?

    export_request.status
  end

  def epub_export_download_url(export_request)
    return unless export_request.downloadable?

    url_for(controller: :downloads, action: :epub_export_file, token: export_request.token, only_path: true)
  end

  def epub_export_error_message(export_request)
    if export_request.expired?
      t('downloads.alerts.expired')
    elsif export_request.failed?
      export_request.error_message
    end
  end

  def epub_export_status_path_for(export_request)
    url_for(controller: :downloads, action: :epub_export_status, token: export_request.token, only_path: true)
  end
end
