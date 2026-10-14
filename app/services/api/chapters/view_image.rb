# frozen_string_literal: true

module Api
  module Chapters
    # One image that is already an img src in a chapter this user can read. It never fetches an arbitrary URL.
    class ViewImage
      def self.call(user:, chapter_id:, url: nil, index: nil)
        new(user:, chapter_id:, url:, index:).call
      end

      def initialize(user:, chapter_id:, url:, index:)
        @user = user
        @chapter_id = chapter_id
        @url = url
        @index = index
      end

      def call
        chapter = Access.new(user).chapter!(chapter_id)
        ::Chapters::ImageView.call(stored_blob(source(chapter.content_html))) ||
          raise(Error.new('unsupported_image', :unprocessable_entity))
      end

      private

      attr_reader :user, :chapter_id, :url, :index

      def source(html)
        srcs = html.to_s.scan(::Chapters::Images::SRC_ATTRIBUTE).map(&:last)
        chosen = url.presence || src_at(srcs)
        raise Error.new('invalid', :unprocessable_entity) if chosen.blank?
        raise Error.new('image_not_in_chapter', :not_found) unless srcs.include?(chosen)

        chosen
      end

      def src_at(srcs)
        position = index.to_i
        return if position < 1

        srcs[position - 1]
      end

      def stored_blob(src)
        ::Chapters::Images.blob_for_url(src) || raise(Error.new('image_not_stored', :not_found))
      end
    end
  end
end
