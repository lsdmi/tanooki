# frozen_string_literal: true

class MemoryMonitorService
  def self.check_memory_usage
    memory_usage = GetProcessMem.new.mb
    Rails.logger.info "Current memory usage: #{memory_usage.round(2)}MB"

    if memory_usage > 800 # Alert if memory usage exceeds 800MB
      Rails.logger.error "CRITICAL: Memory usage is #{memory_usage.round(2)}MB - consider restarting workers"
      return false
    elsif memory_usage > 500 # Warn if memory usage exceeds 500MB
      Rails.logger.warn "WARNING: Memory usage is #{memory_usage.round(2)}MB"
      return false
    end

    true
  end

  def self.clear_caches
    Rails.cache.clear
    GC.start
    Rails.logger.info 'Caches cleared and garbage collection triggered'
  end

  def self.log_memory_stats
    memory = GetProcessMem.new
    Rails.logger.info "Memory Stats - RSS: #{memory.mb.round(2)}MB"
  end
end
