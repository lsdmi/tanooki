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

      def hikka_slug_moved(slug)
        @lines << "hikka_slug moved #{slug}"
      end

      def hikka_slug_kept(slug)
        @lines << "hikka_slug kept_target dropped #{slug}"
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
