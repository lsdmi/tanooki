# frozen_string_literal: true

require 'test_helper'

module Fictions
  class SimilarFictionsTest < ActiveSupport::TestCase
    setup do
      @team = scanlators(:one)
      @common = genres(:two)
      @rare = genres(:three)
    end

    test 'a shared rare genre ranks above a shared common one' do
      base = listed('base', genres: [@common, @rare], team: @team)
      common_match = listed('common-match', genres: [@common], views: 1000)
      rare_match = listed('rare-match', genres: [@rare], views: 1)
      3.times { |index| listed("filler-#{index}", genres: [@common]) }

      ranked = SimilarFictions.new(base).ranked_ids

      assert_equal rare_match.id, ranked.first
      assert_includes ranked, common_match.id
    end

    test 'the same team lifts an equal match and another age band drops it' do
      base = listed('base', genres: [@common], team: @team)
      teammate = listed('teammate', genres: [@common], team: @team)
      stranger = listed('stranger', genres: [@common])
      adult = listed('adult', genres: [@common], content_rating: :eighteen)
      2.times { |index| listed("filler-#{index}", genres: [@rare]) }

      ranked = SimilarFictions.new(base).ranked_ids

      assert_equal [teammate.id, stranger.id], ranked.first(2)
      assert_not_includes ranked, adult.id
    end

    test 'a 16+ work loses less than an 18+ one on a clean page' do
      base = listed('base', genres: [@rare], team: @team)
      teen = listed('teen', genres: [@rare], content_rating: :sixteen)
      adult = listed('adult', genres: [@rare], content_rating: :eighteen)
      6.times { |index| listed("filler-#{index}", genres: [@common]) }

      ranked = SimilarFictions.new(base).ranked_ids

      assert_includes ranked, teen.id
      assert_not_includes ranked, adult.id
    end

    test 'the fiction itself and works without chapters never show' do
      base = listed('base', genres: [@rare], team: @team)
      empty = listed('empty', genres: [@rare], chapter_count: 0)

      ranked = SimilarFictions.new(base).ranked_ids

      assert_not_includes ranked, base.id
      assert_not_includes ranked, empty.id
    end

    test 'without genre matches the team fills the row, then popular works of the same age band' do
      base = listed('base', team: @team)
      team_work = listed('team-work', team: @team, views: 1)
      popular = listed('popular', views: 500)
      listed('popular-adult', views: 900, content_rating: :eighteen)

      assert_equal [team_work.id, popular.id], SimilarFictions.new(base).ranked_ids
    end

    test 'the ranked ids are cached and deleted works drop out' do
      base = listed('base', genres: [@rare], team: @team)
      first, second = %w[first second].map { |slug| listed(slug, genres: [@rare]) }

      assert_equal [first.id, second.id], SimilarFictions.new(base).fictions.map(&:id)

      first.destroy!

      assert_equal [second.id], SimilarFictions.new(base).fictions.map(&:id)
      assert Rails.cache.exist?("similar-to/v2/#{base.id}")
    end

    private

    def listed(slug, genres: [], team: nil, **attributes)
      fiction = Fiction.new(slug:, title: slug, author: 'Author', description: 'd' * 30, chapter_count: 1,
                            **attributes)
      fiction.save!(validate: false)
      genres.each { |genre| FictionGenre.create!(fiction:, genre:) }
      FictionScanlator.create!(fiction:, scanlator: team) if team
      fiction
    end
  end
end
