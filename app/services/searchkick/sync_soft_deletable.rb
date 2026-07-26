# frozen_string_literal: true

module Searchkick
  # Removes soft-deleted rows from OpenSearch and reindexes active records so search
  # counts match rendered results (also heals hard-deletes that bypassed callbacks).
  class SyncSoftDeletable
    MODELS = [YoutubeVideo, Publication, Fiction].freeze

    INDEX_UNAVAILABLE_ERRORS = [Searchkick::MissingIndexError, Searchkick::ImportError].freeze

    def call
      MODELS.each do |model|
        remove_soft_deleted(model)
        reindex(model)
      end
    end

    private

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

      model.only_deleted.find_each do |record|
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
      Rails.logger.info("[searchkick] #{model.name}: reindexing...")
      model.reindex
      Rails.logger.info("[searchkick] #{model.name}: reindex done")
    end
  end
end
