# frozen_string_literal: true

module Chapters
  # Composer list of stored revisions, with the paragraphs that differ and a restore button.
  class RevisionHistoryComponent < ViewComponent::Base
    def initialize(chapter:, list_page:)
      super()
      @chapter = chapter
      @list_page = list_page
    end

    def render?
      revisions.any?
    end

    def revisions
      @revisions ||= chapter.revisions.order(created_at: :desc, id: :desc).limit(20)
    end

    def changes_for(revision)
      RevisionChanges.for(chapter, revision)
    end

    def revert_path(revision)
      helpers.revert_chapter_revision_path(chapter, revision, page: list_page)
    end

    def snippet(text)
      text.to_s.truncate(180)
    end

    private

    attr_reader :chapter, :list_page
  end
end
