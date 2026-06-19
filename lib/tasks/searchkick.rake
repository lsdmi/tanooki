# frozen_string_literal: true

namespace :searchkick do
  desc 'Remove soft-deleted records from OpenSearch and reindex active rows (fixes search count vs results)'
  task sync_soft_deletable: :environment do
    Searchkick::SyncSoftDeletable.new.call
  end
end
