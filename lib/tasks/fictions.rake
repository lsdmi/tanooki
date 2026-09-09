# frozen_string_literal: true

namespace :fictions do
  desc 'Warm fiction index Solid Cache keys (CI / laptop)'
  task warm_index_cache: :environment do
    Fictions::WarmIndexCacheJob.perform_now
    puts 'Fiction index caches warmed.'
  end
end
