# frozen_string_literal: true

module Api
  module V1
    # Chapter list, batch read, number lookup, and create for one fiction.
    class FictionChaptersController < BaseController
      before_action(only: %i[index batch by_number]) { enforce_scope('chapters:read') }
      before_action(only: :create) { enforce_scope('chapters:write') }

      def index
        render json: { chapters: listed.map { |chapter| Api::Chapters::Serialize.summary(chapter) } }
      end

      def batch
        render json: { chapters: capped(listed).map { |chapter| Api::Chapters::Serialize.full(chapter) } }
      end

      def by_number
        matches = numbered.to_a
        raise Api::Error.new('not_found', :not_found) if matches.empty?
        raise ambiguous!(matches) if matches.many?

        render json: Api::Chapters::Serialize.full(matches.first)
      end

      def create
        replay = Api::Idempotency.read(Current.user, idempotency_key)
        return render json: replay.body, status: replay.status if replay

        body = created_body
        Api::Idempotency.write(Current.user, idempotency_key, status: 201, body:)
        render json: body, status: :created
      end

      private

      def listed
        fiction = access.fiction!(params[:fiction_id])
        scope = access.chapters.where(fiction_id: fiction.id).preload(:scanlators, :rich_text_content)
        filter_listed(scope).ordered_by_volume_and_number
      end

      def filter_listed(scope)
        scope = scope.where(chapter_scanlators: { scanlator_id: team_filter }) if params[:team_id].present?
        filter_numbers(scope)
      end

      def filter_numbers(scope)
        scope = scope.where(number: (params[:from])..) if params[:from].present?
        scope = scope.where(number: ..(params[:to])) if params[:to].present?
        scope
      end

      def numbered
        scope = listed.where(number: params[:number])
        return scope if params[:volume].blank?

        scope.where(volume_number: params[:volume])
      end

      def created_body
        outcome = Api::Chapters::Create.call(
          user: Current.user, token: Current.api_token, fiction_id: params[:fiction_id], params: chapter_input
        )
        Api::Chapters::Serialize.full(outcome.chapter, changes: outcome.changes, diff: { summary: 'created' })
      end

      def team_filter
        id = params[:team_id].to_i
        raise Api::Error.new('not_found', :not_found) unless access.member_team_ids.include?(id)

        id
      end

      def capped(chapters)
        picked = []
        chars = 0
        chapters.limit(5).each do |chapter|
          html = chapter.content.to_s
          break if picked.any? && chars + html.length > 200_000

          picked << chapter
          chars += html.length
        end
        picked
      end

      def ambiguous!(matches)
        chapters = matches.map { |chapter| Api::Chapters::Serialize.summary(chapter) }
        Api::Error.new('ambiguous', :conflict, { chapters: })
      end

      def chapter_input
        params.permit(
          :number, :volume_number, :title, :content, :content_format, :status, :published_at, scanlator_ids: []
        )
      end

      def idempotency_key
        request.headers['Idempotency-Key']
      end

      def access
        @access ||= Api::Access.new(Current.user)
      end
    end
  end
end
