# frozen_string_literal: true

namespace :memory do
  desc 'Check memory usage and log stats'
  task check: :environment do
    MemoryMonitorService.check_memory_usage
    MemoryMonitorService.log_memory_stats
  end

  desc 'Clear caches and trigger GC'
  task clear: :environment do
    MemoryMonitorService.clear_caches
  end
end
