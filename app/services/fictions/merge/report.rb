# frozen_string_literal: true

module Fictions
  class Merge
    # Row counts and unique-index resolutions printed by the merge task.
    class Report
      def initialize
        @lines = []
      end

      def count(label, amount)
        @lines << "#{label} #{amount}"
      end

      def conflicts(label, moved:, kept:, removed:)
        @lines << "#{label} moved #{moved} kept_newer #{kept} removed #{removed}"
      end

      def skipped(label, moved:, skipped:)
        @lines << "#{label} moved #{moved} skipped #{skipped}"
      end

      def titles(names)
        @lines << "titles #{names.presence&.join(' ') || 'none'}"
      end

      def already_merged
        'already merged'
      end

      def to_s
        @lines.join("\n")
      end
    end
  end
end
