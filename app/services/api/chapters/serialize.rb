# frozen_string_literal: true

module Api
  module Chapters
    # JSON for a chapter the caller is allowed to see. List rows omit the body.
    class Serialize
      def self.summary(chapter)
        {
          id: chapter.id, fiction_id: chapter.fiction_id, title: chapter.title, status: chapter.status,
          volume_number: json_number(chapter.volume_number), number: json_number(chapter.number),
          published_at: chapter.published_at&.iso8601, team_ids: chapter.scanlators.map(&:id),
          created_via: chapter.created_via, version: version(chapter)
        }
      end

      def self.full(chapter, changes: [], diff: nil)
        summary(chapter).merge(paths(chapter), body(chapter), sanitizer_changes: changes, diff:)
      end

      def self.body(chapter)
        html = chapter.content_html
        { html:, paragraphs: ::Chapters::Paragraphs.list(html) }
      end

      def self.version(chapter)
        Digest::SHA256.hexdigest("#{chapter.title}\n#{chapter.content}")
      end

      def self.check_version!(chapter, given)
        given = given.to_s
        raise Error.new('version', :unprocessable_entity) if given.blank?
        return if given.bytesize == version(chapter).bytesize &&
                  ActiveSupport::SecurityUtils.secure_compare(given, version(chapter))

        raise Error.new('stale', :conflict, { version: version(chapter) })
      end

      def self.paths(chapter)
        {
          public_url: routes.chapter_path(chapter),
          edit_url: routes.edit_chapter_path(chapter)
        }
      end

      def self.json_number(value)
        return if value.nil?

        decimal = value.to_d
        decimal.frac.zero? ? decimal.to_i : decimal.to_f
      end

      def self.routes
        Rails.application.routes.url_helpers
      end

      private_class_method :routes
    end
  end
end
