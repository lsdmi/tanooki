# frozen_string_literal: true

module Pokemons
  module Engine
    # Attacking type => defending type => multiplier, keyed by PokemonType#key (config/type_advantage.yml).
    class TypeChart
      class Incomplete < StandardError; end

      PATH = Rails.root.join('config/type_advantage.yml')

      def self.default
        @default ||= new(YAML.load_file(PATH))
      end

      def initialize(table)
        @table = table.transform_values { |row| row.to_h.transform_values(&:to_f).freeze }.freeze
        validate!
        freeze
      end

      def effectiveness(attacking, defending)
        @table.fetch(attacking).fetch(defending)
      end

      # Every type pair is multiplied, so own types are the outer loop and the opponent's the inner one.
      def multiplier(own_types, opponent_types)
        own_types.reduce(1.0) do |total, attacking|
          opponent_types.reduce(total) { |product, defending| product * effectiveness(attacking, defending) }
        end
      end

      def types
        @table.keys
      end

      private

      def validate!
        problems = @table.flat_map { |attacking, row| row_problems(attacking, row) }
        raise Incomplete, "Type chart: #{problems.join(', ')}" if problems.any?
      end

      def row_problems(attacking, row)
        (types - row.keys).map { |defending| "#{attacking} -> #{defending} missing" } +
          (row.keys - types).map { |defending| "#{attacking} -> #{defending} is not a type" } +
          row.filter_map { |defending, value| "#{attacking} -> #{defending} is #{value}" unless value.positive? }
      end
    end
  end
end
