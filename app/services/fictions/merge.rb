# frozen_string_literal: true

module Fictions
  # Moves chapters, readers, and catalog rows onto the surviving fiction, then soft-deletes the source.
  # One transaction. DRY_RUN=1 prints the same report and rolls the write back.
  # Guest show fragments include the fiction record, so the listing save expires them.
  class Merge
    def self.call(source:, target:, admin:)
      new(source:, target:, admin:).call
    end

    def initialize(source:, target:, admin:)
      @source = source
      @target = target
      @admin = admin
      @report = Report.new
    end

    def call
      check_arguments!
      return finish_existing if already_merged?

      Fiction.transaction { write_all }
      publish! unless dry_run?
      @report.to_s
    end

    private

    def check_arguments!
      raise ArgumentError, 'admin required' unless @admin&.admin?
      raise ArgumentError, 'source and target must differ' if @source.id == @target.id
      raise ArgumentError, 'target is not live' if @target.deleted?
      raise ArgumentError, 'source was merged elsewhere' if merged_elsewhere?
    end

    def already_merged?
      @source.deleted? && @source.merged_into_id == @target.id
    end

    def merged_elsewhere?
      @source.merged_into_id.present? && @source.merged_into_id != @target.id
    end

    def dry_run?
      ActiveModel::Type::Boolean.new.cast(ENV.fetch('DRY_RUN', nil))
    end

    def finish_existing
      publish! unless dry_run?
      @report.already_merged
    end

    def write_all
      Rows.new(source: @source, target: @target, report: @report).call
      Listing.new(source: @source, target: @target, report: @report).call
      retire_source
      raise ActiveRecord::Rollback if dry_run?
    end

    def retire_source
      @source.merged_into = @target
      @source.views = 0
      @source.comments_count = 0
      @source.chapter_count = 0
      @source.last_chapter_at = nil
      @source.save!(validate: false)
      @source.reload.destroy!
    end

    def publish!
      fiction = @target.reload
      expire_fiction_counters(fiction)
      ClaimCleanSlug.new(fiction).call
      expire_fiction_counters(fiction)
      reindex(fiction)
      IndexCachedLists.expire!
      Scanlators::StatsCacheInvalidation.for_scanlator_ids(fiction.scanlators.ids)
    end

    def expire_fiction_counters(fiction)
      Rails.cache.delete("fiction-#{fiction.slug}-stats")
      Rails.cache.delete("fiction-#{fiction.slug}-ranks")
    end

    def reindex(fiction)
      return if SearchkickCallbacks.mode == false

      fiction.reindex
    rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Errno::ECONNREFUSED => e
      Rails.logger.warn("[fictions] merge reindex failed: #{e.message}")
    end
  end
end
