# frozen_string_literal: true

module Pokemons
  class BalanceReport
    # The reports as Markdown, to paste into a balance-change PR: the gates for every version side by side, then the
    # detailed tables of the last one.
    class Markdown
      def self.render(reports)
        new(reports).render
      end

      def initialize(reports)
        @reports = reports
        @report = reports.last
      end

      def render
        [gates, summary, traits, rounds('Type', @report.types, &:itself),
         rounds('Rarity', @report.rarities) { |level| Pokemon::RARITY_LEVELS.key(level) },
         rounds('Might tier', @report.might_tiers, &:itself)].join("\n\n")
      end

      private

      def gates
        header = ['Measure', *@reports.map { |report| "Version #{report.version}" }, 'Target', 'Verdict']
        rows = Gates::ALL.map do |gate|
          values = @reports.map { |report| gate.measure.call(report) }
          verdict = Gates.pass?(gate, values.last) ? 'pass' : 'FAIL'
          [gate.label, *values.map { |value| shown(value) }, gate.target, verdict]
        end
        "### Balance gates (#{@report.battles} battles per measure)\n\n#{grid(header, rows)}"
      end

      def summary
        over = @report.unbalanced_traits.map(&:label)
        verdict = over.empty? ? 'every trait is within target' : "over target: #{over.join(', ')}"
        "Engine v#{@report.version}, #{@report.battles} battles per table: #{verdict}. " \
          "The attacker wins #{percent(@report.attacker_win_rate)} of team battles."
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
        "### #{title}, rounds in team battles\n\n#{grid([title, 'Won', 'Fought', 'Win rate'], cells)}"
      end

      def shown(value)
        case value
        when nil then '—'
        when Array then value.map { |rate| percent(rate) }.join('–')
        when Integer then value.to_s
        else percent(value)
        end
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
