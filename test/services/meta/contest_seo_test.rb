# frozen_string_literal: true

require 'test_helper'

module Meta
  class ContestSeoTest < ActiveSupport::TestCase
    test 'page_title uses archive suffix when results are published' do
      contest = contests(:results)

      title = ContestSeo.new(contest).page_title

      assert_equal 'Конкурс із результатами | Архів конкурсу | Бака', title
    end

    test 'page_title uses live suffix before results' do
      contest = contests(:submissions)

      title = ContestSeo.new(contest).page_title

      assert_equal 'Конкурс подачі | Конкурс ранобе | Бака', title
    end

    test 'meta_description prefers tagline and archive tail' do
      contest = contests(:results)

      description = ContestSeo.new(contest).meta_description

      assert_equal 'Переможці відомі. Підсумки та роботи на Баці.', description
    end

    test 'meta_description uses live tail before results' do
      contest = contests(:submissions)

      description = ContestSeo.new(contest).meta_description

      assert_equal 'Подай твір зараз. Умови, роботи й призи на Баці.', description
    end

    test 'meta_description falls back to description sentence when tagline blank' do
      contest = contests(:results)
      contest.tagline = nil
      contest.description = '<p>Перше речення про конкурс. Друге речення зайве.</p>'

      description = ContestSeo.new(contest).meta_description

      assert_equal 'Перше речення про конкурс. Підсумки та роботи на Баці.', description
    end

    test 'meta_description keeps archive tail when tagline is long' do
      contest = contests(:results)
      contest.tagline = ('Довгий слоган конкурсу з багатьма словами. ' * 8).strip

      description = ContestSeo.new(contest).meta_description

      assert_operator description.length, :<=, ContestSeo::MAX_DESCRIPTION_LENGTH
      assert_match(/Підсумки та роботи на Баці\.\z/, description)
      assert_includes description, '…'
    end

    test 'meta_description keeps live tail when tagline is long' do
      contest = contests(:submissions)
      contest.tagline = ('Довгий слоган конкурсу з багатьма словами. ' * 8).strip

      description = ContestSeo.new(contest).meta_description

      assert_operator description.length, :<=, ContestSeo::MAX_DESCRIPTION_LENGTH
      assert_match(/Умови, роботи й призи на Баці\.\z/, description)
    end
  end
end
