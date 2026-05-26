# frozen_string_literal: true

# Generates EPUB downloads only for chapters whose teams allow conversion.
class DownloadsController < ApplicationController
  def epub
    rich_text = chapter_rich_text(params[:id])
    return handle_forbidden unless epub_allowed?([rich_text&.record])

    generate_and_send_epub(rich_text.id)
  end

  def epub_multiple
    chapters = requested_chapters
    return handle_forbidden unless epub_allowed?(chapters)

    content_ids = chapter_content_ids(chapters)
    generate_and_send_epub(content_ids, params[:volume_title])
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

  def generate_and_send_epub(ids, volume_title = nil)
    epub_export = Books::EpubExport.new(ids, volume_title)
    epub_export.generate
    send_file epub_export.file_path, filename: epub_export.filename, type: 'application/epub+zip'
  rescue StandardError => _e
    handle_error
  end

  def handle_error
    flash[:alert] = t('.error')
    redirect_to request.referer || root_path
  end

  def handle_forbidden
    flash[:alert] = t('.forbidden')
    redirect_to request.referer || root_path
  end
end
