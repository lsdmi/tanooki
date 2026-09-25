# frozen_string_literal: true

module Reading
  # Marks a chapter unread: drops the reads of every translation of it. Never moves the resume cursor.
  # If a pre-rebuild snapshot covers the chapter, the snapshot first becomes real reads so the rest stay read.
  class RemoveRead
    attr_reader :chapter, :user

    def initialize(chapter:, user:)
      @chapter = chapter
      @user = user
    end

    def call
      return false unless user

      progress = ReadingProgress.find_by(user:, fiction:)
      removed = ReadingChapterRead.transaction do
        materialize_legacy(progress)
        delete_reads.positive?
      end
      return false unless removed

      sync_completed_count(progress)
      ProgressCacheInvalidation.new(user, fiction).clear
      true
    end

    private

    def fiction
      chapter.fiction
    end

    def materialize_legacy(progress)
      legacy = ReadKeys.new(user:, fiction:, progress:).legacy_chapter_ids
      return unless legacy.key?(ReadingChapterRead.chapter_key(chapter))

      create_legacy_reads(legacy.values)
      progress.legacy_read_through_chapter_id = nil
      progress.save!(touch: false)
    end

    def create_legacy_reads(chapter_ids)
      now = Time.current
      already_read = ReadingChapterRead.where(user:, chapter_id: chapter_ids).pluck(:chapter_id)
      Chapter.where(id: chapter_ids - already_read).find_each do |legacy_chapter|
        ReadingChapterRead.create!(user:, fiction:, chapter: legacy_chapter, completed_at: now, source: 'legacy')
      end
    end

    # Unscoped: a read of a since-deleted translation still ticks this chapter.
    def delete_reads
      translation_ids = Chapter.unscoped.where(fiction_id: fiction.id, volume_number: chapter.volume_number,
                                               number: chapter.number).select(:id)
      ReadingChapterRead.where(user:, chapter_id: translation_ids).delete_all
    end

    # Unread must not bump the library row's updated_at (it orders the library).
    def sync_completed_count(progress)
      return unless progress

      progress.completed_count = ReadingChapterRead.read_keys(user:, fiction:).size
      progress.save!(touch: false)
    end
  end
end
