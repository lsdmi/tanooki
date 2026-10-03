# frozen_string_literal: true

module Pokemons
  class BalanceReport
    # The report as Markdown tables, to paste into a balance-change PR.
    class Markdown
      def self.render(report)
        new(report).render
      end

      def initialize(report)
        @report = report
      end

      def render
        [summary, traits, rounds('Type', @report.types, &:itself),
         rounds('Rarity', @report.rarities) { |level| Pokemon::RARITY_LEVELS.key(level) },
         rounds('Power level', @report.power_levels) { |level| Pokemon::POWER_LEVELS.key(level) }].join("\n\n")
      end

      private

      def summary
        over = @report.unbalanced_traits.map(&:label)
        verdict = over.empty? ? 'every trait is within target' : "over target: #{over.join(', ')}"
        "Engine v#{Engine::VERSION}, #{@report.battles} battles per table: #{verdict}. " \
          "The attacker wins #{percent(@report.attacker_win_rate)} of random battles."
      end

      def traits
        rows = @report.traits.map do |row|
          [row.label, row.wins, row.total, percent(row.win_rate), row.win_rate > TRAIT_TARGET ? 'over' : '']
        end
        "### Traits, mirror matches (target ≤ #{percent(TRAIT_TARGET)})\n\n" \
          "#{grid(['Trait', 'Wins', 'Battles', 'Win rate', ''], rows)}"
      end

      def rounds(title, rows)
        cells = rows.map { |row| [yield(row.label), row.wins, row.total, percent(row.win_rate)] }
        "### #{title}, rounds in random battles\n\n#{grid([title, 'Won', 'Fought', 'Win rate'], cells)}"
      end

      def grid(header, rows)
        [header, header.map { '---' }, *rows].map { |cells| "| #{cells.join(' | ')} |" }.join("\n")
      end

      def percent(rate)
        format('%.1f%%', rate * 100)
      end
    end
  end
end
