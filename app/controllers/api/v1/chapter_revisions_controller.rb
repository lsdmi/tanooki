# frozen_string_literal: true

module Api
  module V1
    # History of API edits for one chapter the token can already see.
    class ChapterRevisionsController < BaseController
      before_action(only: %i[index diff]) { enforce_scope('chapters:read') }
      before_action(only: :revert) { enforce_scope('chapters:write') }

      def index
        rows = chapter.revisions.order(created_at: :desc, id: :desc).map { |revision| entry(revision) }
        render json: { revisions: rows }
      end

      def diff
        render json: { paragraphs: Api::Chapters::Diff.call(chapter, revision) }
      end

      def revert
        outcome = Api::Chapters::Revert.call(user: Current.user, token: Current.api_token, chapter:, revision:)
        render json: Api::Chapters::Serialize.full(outcome.chapter, diff: { summary: 'reverted' })
      end

      private

      def chapter
        @chapter ||= access.chapter!(params[:chapter_id])
      end

      def revision
        @revision ||= access.revision(chapter.id, params[:id]) || raise(Api::Error.new('not_found', :not_found))
      end

      def entry(revision)
        { id: revision.id, title: revision.title, created_at: revision.created_at.iso8601 }
      end

      def access
        @access ||= Api::Access.new(Current.user)
      end
    end
  end
end
