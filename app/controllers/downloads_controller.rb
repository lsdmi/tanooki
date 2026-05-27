# frozen_string_literal: true

# Queues EPUB exports and serves generated files once background generation finishes.
class DownloadsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_epub_export_request, only: %i[epub_export_status epub_export_file]
  before_action :authorize_epub_export_owner!, only: %i[epub_export_status epub_export_file]

  def epub
    rich_text = chapter_rich_text(params[:id])
    return handle_forbidden unless epub_allowed?([rich_text&.record])

    enqueue_epub_export([rich_text.id])
  end

  def epub_multiple
    chapters = requested_chapters
    return handle_forbidden unless epub_allowed?(chapters)

    content_ids = chapter_content_ids(chapters)
    enqueue_epub_export(content_ids, params[:volume_title])
  end

  def epub_export_status
    render json: epub_export_status_payload(@epub_export_request)
  end

  def epub_export_file
    return handle_forbidden unless @epub_export_request.downloadable?

    redirect_to rails_blob_path(@epub_export_request.file, disposition: :attachment)
  end

  private

  def chapter_rich_text(id)
    ActionText::RichText.find_by(id:, name: 'content', record_type: 'Chapter')
  end

  def requested_chapters
    Chapter.includes(:scanlators).where(id: params[:chapter_ids])
  end

  def chapter_content_ids(chapters)
    ActionText::RichText.where(record_type: 'Chapter', name: 'content', record_id: chapters.map(&:id)).ids
  end

  def epub_allowed?(chapters)
    Books::EpubDownloadPermission.allowed?(Array(chapters).compact)
  end

  def set_epub_export_request
    @epub_export_request = EpubExportRequest.find_by!(token: params[:token])
  end

  def authorize_epub_export_owner!
    return if @epub_export_request.user_id == current_user.id
    return if current_user.admin?

    handle_forbidden
  end

  def enqueue_epub_export(rich_text_ids, volume_title = nil)
    export_request = EpubExportRequest.create!(
      user: current_user,
      rich_text_ids:,
      volume_title:
    )
    Books::GenerateEpubJob.perform_later(export_request.id)

    render json: {
      status: export_request.status,
      status_url: epub_export_status_path_for(export_request)
    }, status: :accepted
  rescue StandardError => _e
    handle_error
  end

  def epub_export_status_payload(export_request)
    {
      status: epub_export_status_value(export_request),
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

  def handle_error
    flash[:alert] = t('downloads.alerts.error')
    redirect_to request.referer || root_path
  end

  def handle_forbidden
    flash[:alert] = t('downloads.alerts.forbidden')
    redirect_to request.referer || root_path
  end
end
