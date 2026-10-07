# frozen_string_literal: true

namespace :fictions do
  desc 'Warm fiction index Solid Cache keys (manual run; scheduled in config/recurring.yml)'
  task warm_index_cache: :environment do
    Fictions::WarmIndexCacheJob.perform_now
    puts 'Fiction index caches warmed.'
  end

  desc 'List non-deleted fictions that share a normalized title, alternative title, or English title'
  task duplicates: :environment do
    puts Fictions::DuplicateGroups.new.to_tsv
  end
end
