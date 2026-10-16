# frozen_string_literal: true

namespace :searchkick do
  desc 'Remove soft-deleted OpenSearch docs (FULL_REINDEX=1 also full-reindexes, batched)'
  task sync_soft_deletable: :environment do
    full_reindex = ENV['FULL_REINDEX'].present?
    Searchkick::SyncSoftDeletable.new(full_reindex: full_reindex).call
  end
end
