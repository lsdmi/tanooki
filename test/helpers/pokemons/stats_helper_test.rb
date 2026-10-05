# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class StatsHelperTest < ActionView::TestCase
    include StatsHelper

    test 'stat_tier_label names the species standing in words' do
      chansey = Pokemon.new(dex_id: 113, base_hp: 250, base_attack: 35)
      labels = %i[stamina strike].map { stat_tier_label(chansey, it) }

      assert_equal ['Дуже висока', 'Дуже слабкий'], labels
      assert_equal 'Немічний', stat_tier_label(Pokemon.new(dex_id: 129, base_hp: 20, base_attack: 15), :might)
    end

    test 'pokemon_type_badge colours the chip by type' do
      render html: pokemon_type_badge('Вогняний')

      assert_select 'span.rounded-full.bg-red-500', text: 'Вогняний'
    end

    test 'experience_to_sentence returns correct sentence for 0' do
      assert_equal 'Відсутній', experience_to_sentence(0)
    end

    test 'experience_to_sentence returns correct sentence for rate in 1..20 range' do
      assert_equal 'Початківець', experience_to_sentence(15)
    end

    test 'experience_to_sentence returns correct sentence for rate in 21..50 range' do
      assert_equal 'Вояк', experience_to_sentence(45)
    end

    test 'experience_to_sentence returns correct sentence for rate in 51..90 range' do
      assert_equal 'Ветеран', experience_to_sentence(70)
    end

    test 'experience_to_sentence returns correct sentence for rate in 91..Float::INFINITY range' do
      assert_equal 'Незборний', experience_to_sentence(100)
    end
  end
end
