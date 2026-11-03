# frozen_string_literal: true

require 'test_helper'

module Contests
  class PresetTest < ActiveSupport::TestCase
    test 'all four presets load and validate' do
      keys = Preset.all.map(&:key)

      assert_equal %w[ranobe short_story fanfiction translation].sort, keys.sort
      Preset.all.to_a.each do |preset|
        assert_equal(100, preset.criteria.sum { |row| row['weight'].to_i })
        assert_equal 100, preset.prize_split.values.sum
      end
    end

    test 'unknown preset raises' do
      assert_raises(Preset::Error) { Preset.find!('nope') }
    end
  end
end
