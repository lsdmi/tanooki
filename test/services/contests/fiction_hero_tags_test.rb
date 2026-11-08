# frozen_string_literal: true

require 'test_helper'

module Contests
  class FictionHeroTagsTest < ActiveSupport::TestCase
    test 'returns entry tag for accepted fiction' do
      fiction = fictions(:one)
      tags = with_discoverable_slug(contests(:submissions).slug) { FictionHeroTags.new(fiction).call }

      assert(tags.any? { |tag| tag.kind == :contest_entry })
      entry = tags.find { |tag| tag.kind == :contest_entry }

      assert_match(/Учасник/, entry.label)
      assert_includes entry.href, '/contests/'
    end

    test 'prefers winner tag when award exists' do
      fiction = fictions(:one)
      entry = contest_entries(:qualified)
      prize = ContestPrize.create!(
        contest: entry.contest,
        position: 0,
        title: '1 місце',
        kind: :place,
        place: 1,
        cash_uah: 0
      )
      ContestAward.create!(
        contest: entry.contest,
        contest_prize: prize,
        contest_entry: entry,
        awarded_at: Time.current
      )

      tags = with_discoverable_slug(entry.contest.slug) { FictionHeroTags.new(fiction).call }
      winner = tags.find { |tag| tag.kind == :contest_winner }

      assert winner
      assert_match(/1 місце/, winner.label)
      assert_equal :contest_winner, tags.first.kind
    end

    test 'a top-five badge replaces the winner pill' do
      fiction = fictions(:one)
      entry = contest_entries(:qualified)
      prize = ContestPrize.create!(
        contest: entry.contest, position: 8, title: '2 місце', kind: :place, place: 2, cash_uah: 0
      )
      ContestAward.create!(
        contest: entry.contest, contest_prize: prize, contest_entry: entry, awarded_at: Time.current
      )

      tags = with_discoverable_slug(entry.contest.slug) do
        Contests::PlaceBadges.stub(:asset?, true) { FictionHeroTags.new(fiction).call }
      end

      assert_nil(tags.find { |tag| tag.kind == :contest_winner })
    end

    test 'omits rejected and withdrawn entries' do
      fiction = fictions(:two)
      tags = with_discoverable_slug(contests(:submissions).slug) { FictionHeroTags.new(fiction).call }

      assert_empty(tags.select { |tag| tag.label.include?(contests(:submissions).title) })
    end

    test 'omits entries for contests that are not publicly discoverable' do
      assert_empty FictionHeroTags.new(fictions(:one)).call
    end

    private

    def with_discoverable_slug(slug, &)
      Contests::PublicAccess.stub(:public_show_slugs, [slug], &)
    end
  end
end
