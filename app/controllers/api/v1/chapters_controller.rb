# frozen_string_literal: true

module Api
  module V1
    # One chapter the token's teams can see, and a partial update of it.
    class ChaptersController < BaseController
      before_action(only: :show) { enforce_scope('chapters:read') }
      before_action(only: %i[update paragraph_edits]) { enforce_scope('chapters:write') }

      def show
        render json: Api::Chapters::Serialize.full(access.chapter!(params[:id]))
      end

      def update
        chapter = access.chapter!(params[:id])
        outcome = Api::Chapters::Update.call(
          user: Current.user, token: Current.api_token, chapter:, params: chapter_input
        )
        render json: Api::Chapters::Serialize.full(outcome.chapter, changes: outcome.changes, diff: outcome.diff)
      end

      def paragraph_edits
        chapter = access.chapter!(params[:id])
        outcome = Api::Chapters::EditParagraphs.call(
          user: Current.user, token: Current.api_token, chapter:, params: paragraph_input
        )
        render json: Api::Chapters::Serialize.full(outcome.chapter, changes: outcome.changes, diff: outcome.diff)
      end

      private

      def chapter_input
        params.permit(
          :number, :volume_number, :title, :content, :content_format, :status, :published_at, :version,
          scanlator_ids: []
        )
      end

      def paragraph_input
        params.permit(:version, edits: %i[n old new])
      end

      def access
        @access ||= Api::Access.new(Current.user)
      end
    end
  end
end
