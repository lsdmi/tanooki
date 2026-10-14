# frozen_string_literal: true

module Api
  module Chapters
    # Stores the chapter as it is now, before a body or title change overwrites it.
    class Revisions
      def self.record!(chapter, user:, token:)
        ChapterRevision.create!(
          chapter:, user:, api_token: api_token(token), oauth_application_id: oauth_application_id(token),
          title: chapter.title.to_s, body: chapter.content_html
        )
      end

      def self.record_change!(chapter, user:, token:, attributes:)
        return unless title_change?(chapter, attributes) || body_change?(chapter, attributes)

        record!(chapter, user:, token:)
      end

      def self.api_token(token)
        token if token.is_a?(ApiToken)
      end

      def self.oauth_application_id(token)
        token.application_id if token.is_a?(OauthAccess)
      end

      def self.title_change?(chapter, attributes)
        attributes.key?(:title) && attributes[:title] != chapter.title
      end

      def self.body_change?(chapter, attributes)
        attributes.key?(:content) && attributes[:content] != chapter.content_html
      end

      private_class_method :api_token, :oauth_application_id, :title_change?, :body_change?
    end
  end
end
