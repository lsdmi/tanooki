# frozen_string_literal: true

namespace :searchkick do
  desc 'Reindex fictions so content_rating and genre_ids reach OpenSearch (one-time deploy step, async)'
  task reindex_fictions: :environment do
    Fiction.reindex(mode: :async)
  end

  desc 'Remove soft-deleted OpenSearch docs (FULL_REINDEX=1 also full-reindexes, batched)'
  task sync_soft_deletable: :environment do
    full_reindex = ENV['FULL_REINDEX'].present?
    Searchkick::SyncSoftDeletable.new(full_reindex: full_reindex).call
  end
end
