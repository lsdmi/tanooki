# frozen_string_literal: true

module Searchkick
  # Removes soft-deleted rows from OpenSearch and optionally full-reindexes active records.
  # Weekly runs cleanup only: a full reindex loads Action Text for every Publication/YoutubeVideo
  # and left the worker ~200 MB higher for hours (see docs/completed/PERFORMANCE_INITIATIVE.md Stream 6).
  class SyncSoftDeletable
    MODELS = [YoutubeVideo, Publication, Fiction].freeze
    REINDEX_BATCH_SIZE = 100

    INDEX_UNAVAILABLE_ERRORS = [Searchkick::MissingIndexError, Searchkick::ImportError].freeze

    def initialize(full_reindex: false)
      @full_reindex = full_reindex
    end

    def call
      MODELS.each { |model| sync_model(model) }
    end

    def sync_model(model)
      remove_soft_deleted(model)
      reindex(model) if full_reindex
      GC.start
    end

    private

    attr_reader :full_reindex

    def remove_soft_deleted(model)
      return skip_missing_index(model) unless model.search_index.exists?

      removed = remove_soft_deleted_records(model)
      log_removed_count(model, removed)
    end

    def skip_missing_index(model)
      Rails.logger.warn("[searchkick] #{model.name}: index missing, skipping soft-delete cleanup")
    end

    def remove_soft_deleted_records(model)
      removed = 0

      model.only_deleted.find_each(batch_size: REINDEX_BATCH_SIZE) do |record|
        remove_soft_deleted_record(model, record)
        removed += 1
      end

      removed
    end

    def remove_soft_deleted_record(model, record)
      model.searchkick_index.remove(record)
    rescue *INDEX_UNAVAILABLE_ERRORS => e
      Rails.logger.warn(
        "[searchkick] #{model.name}: failed to remove #{record.id} from index: #{e.class}"
      )
    end

    def log_removed_count(model, removed)
      Rails.logger.info("[searchkick] #{model.name}: removed #{removed} soft-deleted document(s) from the index")
    end

    def reindex(model)
      Rails.logger.info("[searchkick] #{model.name}: reindexing (batch_size=#{REINDEX_BATCH_SIZE})...")
      with_reindex_batch_size(model) { model.reindex }
      Rails.logger.info("[searchkick] #{model.name}: reindex done")
    end

    # Searchkick reads batch_size from the index options set at `searchkick` declaration time.
    def with_reindex_batch_size(model)
      index = model.searchkick_index
      previous = index.options[:batch_size]
      index.options[:batch_size] = REINDEX_BATCH_SIZE
      yield
    ensure
      index.options[:batch_size] = previous
    end
  end
end
