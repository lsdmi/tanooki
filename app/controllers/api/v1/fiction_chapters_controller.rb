# frozen_string_literal: true

module Api
  module V1
    # Chapter list, batch read, number lookup, and create for one fiction.
    class FictionChaptersController < BaseController
      before_action(only: %i[index batch by_number]) { enforce_scope('chapters:read') }
      before_action(only: :create) { enforce_scope('chapters:write') }

      def index
        render json: { chapters: catalog.summaries(params[:fiction_id], **list_options) }
      end

      def batch
        render json: { chapters: catalog.batch(params[:fiction_id], **list_options) }
      end

      def by_number
        render json: catalog.by_number(params[:fiction_id], params[:number], volume: params[:volume], **list_options)
      end

      def create
        replay = Api::Idempotency.read(Current.user, idempotency_key)
        return render json: replay.body, status: replay.status if replay

        body = created_body
        Api::Idempotency.write(Current.user, idempotency_key, status: 201, body:)
        render json: body, status: :created
      end

      private

      def created_body
        outcome = Api::Chapters::Create.call(
          user: Current.user, token: Current.api_token, fiction_id: params[:fiction_id], params: chapter_input
        )
        Api::Chapters::Serialize.full(outcome.chapter, changes: outcome.changes, diff: { summary: 'created' })
      end

      def list_options
        { team_id: params[:team_id], from: params[:from], to: params[:to] }
      end

      def catalog
        @catalog ||= Api::Chapters::Catalog.new(Current.user)
      end

      def chapter_input
        params.permit(
          :number, :volume_number, :title, :content, :content_format, :status, :published_at, scanlator_ids: []
        )
      end

      def idempotency_key
        request.headers['Idempotency-Key']
      end
    end
  end
end
