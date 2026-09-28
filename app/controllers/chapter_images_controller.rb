# frozen_string_literal: true

# Editor image uploads for chapter bodies (TinyMCE images_upload_handler).
# Stores an unattached blob and returns its URL; saving the chapter attaches it.
class ChapterImagesController < ApplicationController
  MAX_UPLOAD_BYTES = 20.megabytes

  before_action :authenticate_user!
  # Pasting a document uploads every image in it at once.
  rate_limit to: 120, within: 1.minute, by: -> { current_user.id }, only: :create,
             with: -> { render_error(:too_many_requests, t('chapter_images.errors.rate_limited')) }
  before_action :authorize_upload

  def create
    file = params[:file]
    return render_error(:unprocessable_content, t('chapter_images.errors.missing')) unless file.respond_to?(:tempfile)
    return render_error(:content_too_large, too_large_message) if file.size > MAX_UPLOAD_BYTES

    image = Chapters::ImageProcessor.call(file.tempfile.path)
    return render_error(:unprocessable_content, t('chapter_images.errors.unsupported')) unless image

    render json: { location: Chapters::Images.url_for(Chapters::Images.store!(image)) }
  end

  private

  def authorize_upload
    return if current_user.admin? || current_user.scanlators.exists?

    render_error(:forbidden, t('chapter_images.errors.forbidden'))
  end

  def too_large_message
    t('chapter_images.errors.too_large', max: MAX_UPLOAD_BYTES / 1.megabyte)
  end

  def render_error(status, message)
    render json: { error: message }, status:
  end
end
