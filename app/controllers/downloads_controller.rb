# frozen_string_literal: true

class DownloadsController < ApplicationController
  def epub
    generate_and_send_epub(params[:id])
  end

  def epub_multiple
    content_ids = ActionText::RichText.where(record_type: 'Chapter', record_id: params[:chapter_ids]).ids
    generate_and_send_epub(content_ids, params[:volume_title])
  end

  private

  def generate_and_send_epub(ids, volume_title = nil)
    epub_export = Books::EpubExport.new(ids, volume_title)
    epub_export.generate
    send_file epub_export.file_path, filename: epub_export.filename, type: 'application/epub+zip'
  rescue StandardError => _e
    handle_error
  end

  def handle_error
    flash[:alert] = 'Ох, тр*сця! Під час генерування EPUB сталася помилка!'
    redirect_to request.referer || root_path
  end
end
