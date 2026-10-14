# frozen_string_literal: true

module Admin
  # Puts each touched chapter back to the text from before this token's first change since a time.
  # The current text is kept as a new revision. An admin restore does not spend the member's edit cap.
  class RollbackTokenChanges
    Result = Data.define(:restored, :failed)

    def self.call(admin:, revisions:, since:)
      new(admin:, revisions:, since:).call
    end

    def initialize(admin:, revisions:, since:)
      @admin = admin
      @revisions = revisions
      @since = since
    end

    def call
      restored = 0
      failed = 0
      snapshots.each do |revision|
        restore(revision) ? restored += 1 : failed += 1
      end
      Result.new(restored:, failed:)
    end

    private

    attr_reader :admin, :revisions, :since

    def snapshots
      ids = revisions.where(created_at: since..).group(:chapter_id).minimum(:id).values
      ChapterRevision.where(id: ids).includes(:chapter)
    end

    def restore(revision)
      chapter = revision.chapter
      return false unless chapter

      Chapter.transaction do
        Api::Chapters::Revisions.record!(chapter, user: admin, token: nil)
        raise ActiveRecord::Rollback unless save_chapter(chapter, revision)

        true
      end
    end

    def save_chapter(chapter, revision)
      ::Chapters::Persist.call(
        chapter:, attributes: { title: revision.title, content: revision.body }, intent: intent(chapter), user: admin
      )
    end

    def intent(chapter)
      chapter.published? ? ::Chapters::Persist::PUBLISH_INTENT : ::Chapters::Persist::DRAFT_INTENT
    end
  end
end
