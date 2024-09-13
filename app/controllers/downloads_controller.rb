# frozen_string_literal: true

class DownloadsController < ApplicationController
  def epub
    epub_generator = EpubGenerator.new(params[:id])
    epub_generator.generate
    send_file epub_generator.file_path, filename: epub_generator.filename, type: 'application/epub+zip'
  rescue StandardError => _e
    handle_error
  end

  private

  def handle_error
    flash[:alert] = 'Ох, тр*сця! Під час генерування EPUB сталася помилка!'
    redirect_to request.referer || root_path
  end
end
