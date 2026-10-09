# frozen_string_literal: true

module Api
  module Chapters
    # Partial update through Chapters::Persist. A published chapter needs chapters:publish,
    # and a stale version is refused before anything is written.
    class Update
      Result = Data.define(:chapter, :changes, :diff)

      def self.call(user:, token:, chapter:, params:)
        new(user:, token:, chapter:, params:).call
      end

      def initialize(user:, token:, chapter:, params:)
        @user = user
        @token = token
        @chapter = chapter
        @params = params.to_h.with_indifferent_access
        @access = Access.new(user)
        @changes = []
      end

      def call
        ensure_version!
        ensure_scopes!
        attributes = attributes_for
        check_damage!(attributes)
        save!(attributes)
        Result.new(chapter: chapter.reload, changes:, diff:)
      end

      private

      attr_reader :user, :token, :chapter, :params, :access, :changes

      def ensure_version!
        Serialize.check_version!(chapter, params[:version])
      end

      def save!(attributes)
        Chapter.transaction do
          Revisions.record_change!(chapter, user:, token:, attributes:)
          saved = ::Chapters::Persist.call(chapter:, attributes:, intent:, user:)
          raise invalid!(chapter) unless saved
        end
      end

      def ensure_scopes!
        access.ensure_live_edit!(token, chapter)
        return unless publishing?
        return if token&.permits?('chapters:publish')

        raise Error.new('publish_scope', :forbidden)
      end

      def attributes_for
        attrs = {}
        assign_scalars(attrs)
        assign_content(attrs)
        assign_teams(attrs)
        attrs[:published_at] = parsed_time if params.key?(:published_at)
        attrs
      end

      def assign_scalars(attrs)
        attrs[:title] = params[:title].to_s if params.key?(:title)
        attrs[:number] = params[:number] if params.key?(:number)
        assign_volume(attrs)
      end

      def assign_volume(attrs)
        attrs[:volume_number] = params[:volume_number].presence if params.key?(:volume_number)
      end

      def assign_content(attrs)
        return unless params.key?(:content)

        prepared = Content.call(params[:content], params[:content_format])
        @changes = prepared.changes
        attrs[:content] = prepared.html
      end

      def assign_teams(attrs)
        return unless params.key?(:scanlator_ids)

        attrs[:scanlator_ids] = access.scanlator_ids!(chapter.fiction, params[:scanlator_ids]).map(&:to_s)
      end

      def check_damage!(attributes)
        return unless chapter.published?
        return Limits.new(user).record_unpublish! if params[:status].to_s == 'draft'
        return unless attributes.key?(:content) || attributes.key?(:title)

        refuse_shrink!(attributes)
        Limits.new(user).record_published_edit!
      end

      def refuse_shrink!(attributes)
        return unless attributes.key?(:content)

        Limits.refuse_published_rewrite!(chapter.content_html, attributes[:content])
      end

      def publishing?
        params[:status].to_s == 'published' || params[:published_at].present?
      end

      def intent
        return ::Chapters::Persist::DRAFT_INTENT if params[:status].to_s == 'draft'
        return ::Chapters::Persist::PUBLISH_INTENT if publishing?

        chapter.published? ? ::Chapters::Persist::PUBLISH_INTENT : ::Chapters::Persist::DRAFT_INTENT
      end

      def parsed_time
        value = params[:published_at]
        return if value.blank?

        Time.zone.parse(value.to_s) || raise(Error.new('published_at', :unprocessable_entity))
      rescue ArgumentError
        raise Error.new('published_at', :unprocessable_entity)
      end

      def diff
        { summary: changes.present? ? 'sanitized' : 'updated' }
      end

      def invalid!(record)
        Error.new('invalid', :unprocessable_entity, record.errors.messages)
      end
    end
  end
end
