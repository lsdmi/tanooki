# frozen_string_literal: true

module Api
  module Chapters
    # Replaces numbered blocks. Blocks left out of the edit keep their HTML, including styles and notes.
    class EditParagraphs
      Result = Data.define(:chapter, :changes, :diff)

      def self.call(user:, token:, chapter:, params:)
        new(user:, token:, chapter:, params:).call
      end

      def initialize(user:, token:, chapter:, params:)
        @user = user
        @token = token
        @chapter = chapter
        @params = params.to_h.with_indifferent_access
        @changes = []
      end

      def call
        Serialize.check_version!(chapter, params[:version])
        Access.new(user).ensure_live_edit!(token, chapter)
        html = edited_html
        charge_published_edit!
        save!(html)
        Result.new(chapter: chapter.reload, changes:, diff: { summary: 'paragraphs' })
      end

      private

      attr_reader :user, :token, :chapter, :params, :changes

      def edited_html
        Limits.refuse_too_many_blocks!(edits.size)
        ::Chapters::Paragraphs.apply(chapter.content_html, edits, changes:)
      end

      def edits
        Array(params[:edits])
      end

      def charge_published_edit!
        return unless chapter.published?

        Limits.new(user).record_published_edit!
      end

      def save!(html)
        Chapter.transaction do
          Revisions.record!(chapter, user:, token:)
          saved = ::Chapters::Persist.call(chapter:, attributes: { content: html }, intent:, user:)
          raise Error.new('invalid', :unprocessable_entity, chapter.errors.messages) unless saved
        end
      end

      def intent
        chapter.published? ? ::Chapters::Persist::PUBLISH_INTENT : ::Chapters::Persist::DRAFT_INTENT
      end
    end
  end
end
