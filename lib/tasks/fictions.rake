# frozen_string_literal: true

namespace :fictions do
  desc 'Warm fiction index Solid Cache keys (CI / laptop)'
  task warm_index_cache: :environment do
    Fictions::WarmIndexCacheJob.perform_now
    puts 'Fiction index caches warmed.'
  end

  desc 'Mark inactive ongoing / never-started announced fictions as dropped (CI / laptop)'
  task refresh_dropped_status: :environment do
    result = Fictions::RefreshDroppedStatus.call

    puts "scanned ongoing=#{result.scanned_ongoing} announced=#{result.scanned_announced}"
    puts "dropped ongoing=#{result.dropped_ongoing} announced=#{result.dropped_announced}"
    puts "catalog ongoing=#{result.total_ongoing} announced=#{result.total_announced} " \
         "dropped=#{result.total_dropped} finished=#{result.total_finished}"
    puts "errors=#{result.errors.size}"
    result.errors.each { |error| puts "  fiction=#{error[:fiction_id]} #{error[:error]}" }

    abort 'fictions:refresh_dropped_status failed' if result.errors.any?
  end
end
