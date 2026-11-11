# frozen_string_literal: true

module Api
  module Chapters
    # JSON for a chapter the caller is allowed to see. List rows omit body and version.
    # Full payloads hash version from content_html (ActionText#to_s is too slow on large bodies).
    class Serialize
      def self.summary(chapter)
        {
          id: chapter.id, fiction_id: chapter.fiction_id, title: chapter.title, status: chapter.status,
          volume_number: json_number(chapter.volume_number), number: json_number(chapter.number),
          published_at: chapter.published_at&.iso8601, team_ids: chapter.scanlators.map(&:id),
          created_via: chapter.created_via
        }
      end

      def self.full(chapter, changes: [], diff: nil, body: :all)
        html = chapter.content_html
        summary(chapter).merge(
          paths(chapter), body_fields(html, body), version: digest(chapter.title, html),
                                                   sanitizer_changes: changes, diff:
        )
      end

      def self.body(chapter)
        body_fields(chapter.content_html, :all)
      end

      # Hash the same HTML the API returns. ActionText#to_s is much slower on large bodies.
      def self.version(chapter)
        digest(chapter.title, chapter.content_html)
      end

      def self.check_version!(chapter, given)
        given = given.to_s
        raise Error.new('version', :unprocessable_entity) if given.blank?

        current = version(chapter)
        return if given.bytesize == current.bytesize &&
                  ActiveSupport::SecurityUtils.secure_compare(given, current)

        raise Error.new('stale', :conflict, { version: current })
      end

      def self.body_fields(html, body)
        case body.to_sym
        when :html then { html: }
        when :paragraphs then { paragraphs: ::Chapters::Paragraphs.list(html) }
        else { html:, paragraphs: ::Chapters::Paragraphs.list(html) }
        end
      end

      def self.digest(title, html)
        Digest::SHA256.hexdigest("#{title}\n#{html}")
      end

      private_class_method :body_fields, :digest

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
