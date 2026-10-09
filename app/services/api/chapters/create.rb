# frozen_string_literal: true

module Api
  module Chapters
    # Creates one chapter through Chapters::Persist. Team checks go through Api::Access,
    # never User#manages_chapter? or Chapters::Authorization (those let an admin through).
    class Create
      Result = Data.define(:chapter, :changes)

      def self.call(user:, token:, fiction_id:, params:)
        new(user:, token:, fiction_id:, params:).call
      end

      def initialize(user:, token:, fiction_id:, params:)
        @user = user
        @token = token
        @fiction_id = fiction_id
        @params = params.to_h.with_indifferent_access
        @access = Access.new(user)
      end

      def call
        fiction = find_fiction!
        attributes = attributes_for(fiction)
        ensure_publish_allowed!
        reserve!(fiction, attributes)
        Result.new(chapter: save!(attributes), changes: @changes)
      end

      private

      attr_reader :user, :token, :fiction_id, :params, :access

      def attributes_for(fiction)
        {
          fiction_id: fiction.id, number: params[:number], title: params[:title].to_s,
          volume_number: params[:volume_number].presence, content: prepared_html,
          scanlator_ids: team_ids(fiction), published_at: publishing? ? parsed_time : nil
        }
      end

      def prepared_html
        prepared = Content.call(params[:content], params[:content_format])
        @changes = prepared.changes
        prepared.html
      end

      def reserve!(fiction, attributes)
        existing = same_slot(fiction, attributes)
        raise conflict_error(existing) if existing

        Limits.new(user).record_create!
      end

      def save!(attributes)
        chapter = Chapter.new(user:, created_via: 'api', api_token: token)
        saved = ::Chapters::Persist.call(chapter:, attributes:, intent:, user:)
        raise invalid!(chapter) unless saved

        chapter
      end

      def find_fiction!
        key = fiction_id.to_s
        Fiction.find_by(id: key) || Fiction.find_by(slug: key) || raise(Error.new('not_found', :not_found))
      end

      def team_ids(fiction)
        ids = params.key?(:scanlator_ids) ? params[:scanlator_ids] : default_team_ids(fiction)
        access.scanlator_ids!(fiction, ids).map(&:to_s)
      end

      def default_team_ids(fiction)
        fiction.scanlators.ids & access.member_team_ids
      end

      def same_slot(fiction, attributes)
        scope = access.chapters.where(fiction_id: fiction.id, number: attributes[:number])
        volume = attributes[:volume_number]
        scope = volume.nil? ? scope.where(volume_number: nil) : scope.where(volume_number: volume)
        scope.first
      end

      def publishing?
        params[:status].to_s == 'published' || params[:published_at].present?
      end

      def ensure_publish_allowed!
        return unless publishing?
        return if token&.permits?('chapters:publish')

        raise Error.new('publish_scope', :forbidden)
      end

      def intent
        publishing? ? ::Chapters::Persist::PUBLISH_INTENT : ::Chapters::Persist::DRAFT_INTENT
      end

      def parsed_time
        value = params[:published_at]
        return if value.blank?

        Time.zone.parse(value.to_s) || raise(Error.new('published_at', :unprocessable_entity))
      rescue ArgumentError
        raise Error.new('published_at', :unprocessable_entity)
      end

      def conflict_error(chapter)
        Error.new('conflict', :conflict, { id: chapter.id }.merge(Serialize.paths(chapter)))
      end

      def invalid!(chapter)
        Error.new('invalid', :unprocessable_entity, chapter.errors.messages)
      end
    end
  end
end
