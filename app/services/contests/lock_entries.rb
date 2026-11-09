# frozen_string_literal: true

require 'digest'

module Contests
  # At submissions_close_at: snapshot judged chapters, freeze authors, set qualified/incomplete.
  # Idempotent — only accepted entries without locked_snapshot are processed.
  class LockEntries
    class Error < StandardError; end

    def self.call(**) = new(**).tap(&:call)

    def initialize(contest:, at: Time.current)
      @contest = contest
      @at = at
    end

    def call
      raise Error, I18n.t('contests.lock.not_closed') if contest.submissions_close_at > at
      raise Error, I18n.t('contests.lock.cancelled') if contest.cancelled?

      @locked_count = 0
      Contest.transaction do
        lockable_entries.each { |entry| lock_entry!(entry) }
      end
      self
    end

    attr_reader :locked_count

    private

    attr_reader :contest, :at

    def lockable_entries
      contest.entries.accepted.where(locked_snapshot: nil).includes(:fiction)
    end

    def lock_entry!(entry)
      progress = RequirementsProgress.new(entry)
      snapshot = build_snapshot(progress.judged_chapters)
      sync_authors!(entry)
      entry.update!(
        locked_snapshot: snapshot,
        status: progress.all_met? ? :qualified : :incomplete
      )
      @locked_count += 1
    end

    def build_snapshot(chapters)
      rows = chapters.map do |chapter|
        plain = chapter.content.to_plain_text.to_s
        {
          'chapter_id' => chapter.id,
          'digest' => Digest::SHA256.hexdigest(plain)
        }
      end
      { 'chapters' => rows }
    end

    def sync_authors!(entry)
      fiction = entry.fiction
      author_ids = fiction ? fiction.users.ids : []
      author_ids = [entry.submitter_id].compact if author_ids.blank?
      entry.entry_authors.where.not(user_id: author_ids).find_each(&:destroy)
      author_ids.each { |user_id| entry.entry_authors.find_or_create_by!(user_id:) }
    end
  end
end
