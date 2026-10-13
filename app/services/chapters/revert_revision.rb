# frozen_string_literal: true

module Chapters
  # Puts a chapter back to a stored revision. The current text is kept as a new revision.
  class RevertRevision
    def self.call(user:, chapter:, revision:)
      new(user:, chapter:, revision:).call
    end

    def initialize(user:, chapter:, revision:)
      @user = user
      @chapter = chapter
      @revision = revision
    end

    def call
      raise Api::Error.new('not_found', :not_found) unless revision&.chapter_id == chapter.id

      Api::Limits.new(user).record_published_edit! if chapter.published?
      restore!
    end

    private

    attr_reader :user, :chapter, :revision

    def restore!
      Chapter.transaction do
        Api::Chapters::Revisions.record!(chapter, user:, token: nil)
        saved = Persist.call(chapter:, attributes: restore_attributes, intent:, user:)
        raise Api::Error.new('invalid', :unprocessable_entity) unless saved
      end
    end

    def restore_attributes
      { title: revision.title, content: revision.body }
    end

    def intent
      chapter.published? ? Persist::PUBLISH_INTENT : Persist::DRAFT_INTENT
    end
  end
end
