# frozen_string_literal: true

require 'test_helper'

class TurboFalseAllowlistTest < ActiveSupport::TestCase
  TURBO_FALSE_PATTERN = /turbo:\s*false|turbo="false"/
  SCAN_ROOTS = %w[app/views app/helpers app/components].freeze
  ALLOWLIST_PATH = Rails.root.join('config/turbo_false_allowlist.yml')

  test 'every turbo false in views helpers and components is on the allowlist' do
    uncovered = turbo_false_occurrences.reject { |occurrence| covered_by_allowlist?(occurrence) }

    assert_empty uncovered,
                 "Unexpected data-turbo=false (add to #{ALLOWLIST_PATH} or remove):\n" \
                 "#{format_occurrences(uncovered)}"
  end

  test 'allowlist has no stale entries' do
    stale = allowlist_entries.reject { |entry| allowlist_entry_present?(entry) }

    assert_empty stale,
                 "Stale allowlist entries (remove from #{ALLOWLIST_PATH}):\n#{stale.join("\n")}"
  end

  test 'allowlist count stays within intentional ceiling' do
    assert_operator turbo_false_occurrences.size, :<=, 22,
                    'Re-audit allowlist if intentional turbo:false grows beyond ceiling'
  end

  private

  def turbo_false_occurrences
    SCAN_ROOTS.flat_map { |root| occurrences_in_root(root) }
  end

  def occurrences_in_root(root)
    Rails.root.glob("#{root}/**/*").flat_map do |absolute_path|
      next [] unless absolute_path.file?
      next [] unless absolute_path.to_s.match?(/\.(erb|rb|html)\z$/)

      relative_path = absolute_path.relative_path_from(Rails.root).to_s
      turbo_false_lines_in_file(absolute_path, relative_path)
    end
  end

  def turbo_false_lines_in_file(absolute_path, relative_path)
    absolute_path.each_line.with_index(1).filter_map do |line, line_number|
      next unless line.match?(TURBO_FALSE_PATTERN)

      { path: relative_path, line: line_number }
    end
  end

  def allowlist_entries
    entries = YAML.load_file(ALLOWLIST_PATH).fetch('allowed')
    raise "Missing allowed key in #{ALLOWLIST_PATH}" unless entries.is_a?(Array)

    entries
  end

  def covered_by_allowlist?(occurrence)
    allowlist_entries.any? { |entry| allowlist_entry_matches?(entry, occurrence) }
  end

  def allowlist_entry_matches?(entry, occurrence)
    file, line = entry.split(':', 2)

    return false unless file == occurrence[:path]
    return true if line.nil?

    line.to_i == occurrence[:line]
  end

  def allowlist_entry_present?(entry)
    file, line = entry.split(':', 2)
    path = Rails.root.join(file)

    return false unless path.file?

    line ? turbo_false_on_line?(path, line.to_i) : path.each_line.any? { |content| content.match?(TURBO_FALSE_PATTERN) }
  end

  def turbo_false_on_line?(path, line_number)
    path.each_line.with_index(1).any? do |content, index|
      index == line_number && content.match?(TURBO_FALSE_PATTERN)
    end
  end

  def format_occurrences(occurrences)
    occurrences.map { |occurrence| "  #{occurrence[:path]}:#{occurrence[:line]}" }.join("\n")
  end
end
