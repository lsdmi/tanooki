# frozen_string_literal: true

module Searchkick
  # Removes soft-deleted rows from OpenSearch and reindexes active records so search
  # counts match rendered results (also heals hard-deletes that bypassed callbacks).
  class SyncSoftDeletable
    MODELS = [YoutubeVideo, Publication, Fiction].freeze

    def call
      MODELS.each do |model|
        remove_soft_deleted(model)
        reindex(model)
      end
    end

    private

    def remove_soft_deleted(model)
      removed = 0

      model.only_deleted.find_each do |record|
        model.searchkick_index.remove(record)
        removed += 1
      end

      Rails.logger.info("[searchkick] #{model.name}: removed #{removed} soft-deleted document(s) from the index")
    end

    def reindex(model)
      Rails.logger.info("[searchkick] #{model.name}: reindexing...")
      model.reindex
      Rails.logger.info("[searchkick] #{model.name}: reindex done")
    end
  end
end
