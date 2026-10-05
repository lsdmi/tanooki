# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class BalanceReport
    class FieldTest < ActiveSupport::TestCase
      SPECIES = [[129, 20, 15], [16, 40, 45], [143, 160, 110]].map do |dex_id, hp, attack|
        Species.new(id: dex_id, dex_id:, name: "S#{dex_id}", rarity: 1, types: %w[normal], base_hp: hp,
                    base_attack: attack)
      end.freeze

      test 'rates each species by dex number, stronger ones higher' do
        rates = field.rates

        assert_equal [129, 16, 143], rates.keys
        assert_equal rates.values.sort, rates.values
      end

      test 'the same seed gives the same rates without touching the database' do
        rates = assert_no_queries { field.rates }

        assert_equal field.rates, rates
      end

      private

      def field
        Field.new(species: SPECIES, repeats: 10, seed: 3)
      end
    end
  end
end
