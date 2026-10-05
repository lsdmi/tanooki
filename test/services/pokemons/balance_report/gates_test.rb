# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class BalanceReport
    class GatesTest < ActiveSupport::TestCase
      test 'judges rates against their target' do
        upsets = gate('Weaker species wins (strength gap > 1.3×)')

        assert Gates.pass?(upsets, 0.2)
        assert_not Gates.pass?(upsets, 0.31)
      end

      test 'every trait must be in range' do
        traits = gate('Trait mirror matches')

        assert Gates.pass?(traits, [0.46, 0.54])
        assert_not Gates.pass?(traits, [0.46, 0.56])
      end

      test 'a version without the measure fails it' do
        assert_not Gates.pass?(gate('First striker wins the round'), nil)
      end

      private

      def gate(label)
        Gates::ALL.find { |gate| gate.label == label }
      end
    end
  end
end
