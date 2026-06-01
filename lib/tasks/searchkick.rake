# frozen_string_literal: true

namespace :searchkick do
  desc 'Remove soft-deleted records from OpenSearch and reindex active rows (fixes search count vs results)'
  task sync_soft_deletable: :environment do
    [YoutubeVideo, Publication, Fiction].each do |model|
      removed = 0
      model.only_deleted.find_each do |record|
        model.searchkick_index.remove(record)
        removed += 1
      end
      puts "[searchkick] #{model.name}: removed #{removed} soft-deleted document(s) from the index"

      print "[searchkick] #{model.name}: reindexing... "
      model.reindex
      puts 'done'
    end
  end
end
