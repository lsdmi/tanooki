# frozen_string_literal: true

module Api
  module Chapters
    # Restores a chapter to a revision and keeps a snapshot of what was overwritten.
    class Revert
      Result = Data.define(:chapter, :revision)

      def self.call(user:, token:, chapter:, revision:)
        new(user:, token:, chapter:, revision:).call
      end

      def initialize(user:, token:, chapter:, revision:)
        @user = user
        @token = token
        @chapter = chapter
        @revision = revision
      end

      def call
        authorize!
        raise Error.new('invalid', :unprocessable_entity, chapter.errors.messages) unless restore!

        Result.new(chapter: chapter.reload, revision:)
      end

      private

      attr_reader :user, :token, :chapter, :revision

      def authorize!
        Access.new(user).ensure_live_edit!(token, chapter)
        Limits.new(user).record_published_edit! if chapter.published?
      end

      def restore!
        Chapter.transaction do
          Revisions.record!(chapter, user:, token:)
          ::Chapters::Persist.call(
            chapter:, attributes: { title: revision.title, content: revision.body }, intent:, user:
          )
        end
      end

      def intent
        chapter.published? ? ::Chapters::Persist::PUBLISH_INTENT : ::Chapters::Persist::DRAFT_INTENT
      end
    end
  end
end
