# frozen_string_literal: true

module Reading
  # Folds a guest's device record for one fiction into the signed-in account (P3.2).
  # - Read sets are unioned, sparse as ever, and only with chapters this user can list.
  # - The resume cursor goes to whichever side engaged last (`resume_at`; `updated_at` on rows from before resume_at
  #   existed), so signing in never rewinds a newer account cursor. The device locator comes along only with its
  #   own chapter.
  # Returns true when anything was written.
  class MergeGuestRecord
    SOURCE = 'device'

    def initialize(user:, record:)
      @user = user
      @record = record
    end

    def call
      fiction = Fiction.find_by(id: @record.fiction_id)
      return false unless fiction

      changed = ReadingProgress.transaction { merge(fiction) }.present?
      ProgressCacheInvalidation.new(@user, fiction).clear if changed
      changed
    end

    private

    # The saved library row, or nil when the device had nothing new.
    def merge(fiction)
      listable = Library::ChapterCatalog.chapters_scope_for_list(fiction, @user)
      read_ids = listable.where(id: @record.read_chapter_ids).pluck(:id)
      added = insert_reads(fiction, read_ids)
      progress = ReadingProgress.find_or_initialize_by(user: @user, fiction:)
      moved = move_cursor(progress, cursor_chapter(listable, read_ids, progress)).present?
      return if added.empty? && !moved

      progress.completed_count = ReadingChapterRead.read_keys(user: @user, fiction:).size
      progress.save!(touch: moved)
      progress
    end

    # The chapter ids newly read on this account.
    def insert_reads(fiction, read_ids)
      new_ids = read_ids - ReadingChapterRead.where(user: @user, chapter_id: read_ids).pluck(:chapter_id)
      new_ids.select do |chapter_id|
        ReadingChapterRead.create!(user: @user, fiction:, chapter_id:, completed_at: Time.current, source: SOURCE)
      rescue ActiveRecord::RecordNotUnique
        nil
      end
    end

    # A fresh library row needs a chapter: without a listable device cursor, the latest chapter read on the device.
    def cursor_chapter(listable, read_ids, progress)
      cursor = listable.find_by(id: @record.chapter_id) if @record.chapter_id
      return cursor if cursor || progress.persisted? || read_ids.empty?

      listable.where(id: read_ids).order(Library::ChapterCatalog.order_clause_desc).first
    end

    # The chapter the cursor moved to, or nil when the account cursor stays.
    def move_cursor(progress, chapter)
      return unless chapter && device_newer?(progress)

      locator = @record.locator if chapter.id == @record.chapter_id
      progress.chapter = chapter
      progress.resume_at = @record.resume_at || Time.current
      progress.assign_attributes(locator&.attributes || ResumeLocator::CLEARED)
      chapter
    end

    def device_newer?(progress)
      return true if progress.new_record?
      return false unless @record.resume_at

      @record.resume_at > (progress.resume_at || progress.updated_at)
    end
  end
end
