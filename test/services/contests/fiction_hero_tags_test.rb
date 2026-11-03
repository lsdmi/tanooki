# frozen_string_literal: true

require 'test_helper'

module Contests
  class FictionHeroTagsTest < ActiveSupport::TestCase
    test 'returns entry tag for accepted fiction' do
      fiction = fictions(:one)
      tags = FictionHeroTags.new(fiction).call

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

      tags = FictionHeroTags.new(fiction).call
      winner = tags.find { |tag| tag.kind == :contest_winner }

      assert winner
      assert_match(/1 місце/, winner.label)
      assert_equal :contest_winner, tags.first.kind
    end

    test 'omits rejected and withdrawn entries' do
      fiction = fictions(:two)
      tags = FictionHeroTags.new(fiction).call

      assert_empty(tags.select { |tag| tag.label.include?(contests(:submissions).title) })
    end
  end
end
