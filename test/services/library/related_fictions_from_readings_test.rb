# frozen_string_literal: true

require 'test_helper'

module Library
  class RelatedFictionsFromReadingsTest < ActiveSupport::TestCase
    setup do
      @fiction_one = fictions(:one)
      @fiction_two = fictions(:two)
      @reading = reading_progresses(:one)
      clear_related_fictions_cache(@fiction_one, @fiction_two)
    end

    test 'call returns related fictions from reading progress' do
      results = RelatedFictionsFromReadings.new([@reading]).call

      assert_includes results.map(&:id), @fiction_two.id
      assert_not_includes results.map(&:id), @fiction_one.id
    end

    test 'call returns empty array when readings are empty' do
      assert_empty RelatedFictionsFromReadings.new([]).call
    end

    test 'call respects exclude_ids' do
      results = RelatedFictionsFromReadings.new(
        [@reading],
        exclude_ids: Set[@fiction_two.id]
      ).call

      assert_empty results
    end

    test 'call respects limit' do
      results = RelatedFictionsFromReadings.new(
        [reading_progresses(:one), reading_progresses(:two)],
        1
      ).call

      assert_equal 1, results.size
    end

    test 'call does not duplicate the same related fiction' do
      results = RelatedFictionsFromReadings.new([@reading, @reading]).call

      assert_equal 1, results.size
      assert_equal @fiction_two.id, results.first.id
    end

    private

    def clear_related_fictions_cache(*fictions)
      fictions.each { |fiction| Rails.cache.delete("related-to-#{fiction.slug}") }
    end
  end
end
