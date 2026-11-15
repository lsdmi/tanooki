# frozen_string_literal: true

namespace :paragraph_reports do
  desc 'Print paragraph report kill/keep stats for the last 28 days'
  task stats: :environment do
    stats = ParagraphReports::WindowStats.build
    puts "paragraph_reports window=#{stats.window_days}d"
    stats.to_h.each { |key, value| puts "  #{key}: #{value}" }
  end
end
