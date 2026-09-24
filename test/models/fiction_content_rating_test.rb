# frozen_string_literal: true

require 'test_helper'

class FictionContentRatingTest < ActiveSupport::TestCase
  setup do
    @everyone = fictions(:one)
    @sixteen = fictions(:two)
    @eighteen = fictions(:eighteen)
  end

  test 'enum stores everyone, sixteen, and eighteen as ordinal integers' do
    assert_equal({ 'everyone' => 0, 'sixteen' => 16, 'eighteen' => 18 }, Fiction.content_ratings)
    assert_equal %w[everyone sixteen eighteen], [@everyone, @sixteen, @eighteen].map(&:content_rating)
  end

  test 'new fictions default to everyone' do
    assert_predicate Fiction.new, :content_rating_everyone?
  end

  test 'everyone is unlabelled' do
    assert_not @everyone.age_gated?
    assert_not @everyone.age_labelled?
  end

  test 'sixteen is labelled and not gated' do
    assert_not @sixteen.age_gated?
    assert_predicate @sixteen, :age_labelled?
  end

  test 'eighteen is gated' do
    assert_predicate @eighteen, :age_gated?
    assert_predicate @eighteen, :age_labelled?
  end

  test 'rejects a rating outside the three bands' do
    @everyone.content_rating = 12

    assert_not @everyone.valid?
    assert @everyone.errors.of_kind?(:content_rating, :inclusion)
  end

  test 'not_eighteen keeps sixteen and drops eighteen' do
    ids = [@everyone.id, @sixteen.id]

    assert_equal ids, Fiction.not_eighteen.order(:id).pluck(:id)
  end

  test 'rated_at_most compares the ordinal' do
    expected = {
      everyone: [@everyone.id],
      sixteen: [@everyone.id, @sixteen.id],
      eighteen: [@everyone.id, @sixteen.id, @eighteen.id]
    }

    expected.each do |band, ids|
      assert_equal ids, Fiction.rated_at_most(Fiction.content_ratings[band]).order(:id).pluck(:id)
    end
  end

  test 'discovery scope compares with less-than-or-equal instead of OR' do
    sql = Fiction.not_eighteen.to_sql

    assert_match(/content_rating[`"]? <= /, sql)
    assert_no_match(/\bOR\b/, sql)
  end

  test 'backfill maps adult_content true to eighteen and does not invent sixteen' do
    migration = Rails.root.join('db/migrate/20260923180000_replace_adult_content_with_content_rating.rb').read

    assert_match 'UPDATE fictions SET content_rating = 18 WHERE adult_content = true', migration
    assert_match 'remove_column :fictions, :adult_content', migration
    assert_no_match(/content_rating = 16/, migration)
  end
end
