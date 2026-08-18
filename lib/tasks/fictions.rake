# frozen_string_literal: true

namespace :fictions do
  desc 'Mark inactive unfinished fictions as dropped (CI / laptop)'
  task refresh_dropped_status: :environment do
    result = Fictions::RefreshDroppedStatus.call

    puts "checked=#{result.checked} dropped=#{result.dropped} errors=#{result.errors.size}"
    result.errors.each { |error| puts "  fiction=#{error[:fiction_id]} #{error[:error]}" }

    abort 'fictions:refresh_dropped_status failed' if result.errors.any?
  end
end
