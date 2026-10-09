# frozen_string_literal: true

module Api
  module V1
    # Stores one image for a chapter body. The caller then puts the returned URL in Markdown.
    class ChapterImagesController < BaseController
      MAX_UPLOAD_BYTES = 20.megabytes

      before_action { enforce_scope('images:write') }

      def create
        image = ::Chapters::ImageProcessor.call(source_path)
        raise Error.new('unsupported_image', :unprocessable_entity) if image.nil?

        blob = ::Chapters::Images.store!(image)
        render json: { url: ::Chapters::Images.url_for(blob) }, status: :created
      ensure
        @download&.close!
      end

      private

      def source_path
        return uploaded_path if params[:file].present?
        return downloaded_path if params[:url].present?

        raise Error.new('image_missing', :unprocessable_entity)
      end

      def uploaded_path
        file = params[:file]
        raise Error.new('image_too_large', :content_too_large) if file.size > MAX_UPLOAD_BYTES

        file.tempfile.path
      end

      def downloaded_path
        @download = UrlFetch.to_tempfile(params[:url].to_s)
        @download.path
      end
    end
  end
end
