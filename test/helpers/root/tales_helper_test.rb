# frozen_string_literal: true

require 'test_helper'

module Root
  class TalesHelperTest < ActionView::TestCase
    include TalesHelper

    test 'home_tales_editorial_cards partitions top tale as hero and four side tales' do
      hero = publications(:tale_approved_one)
      side = [
        publications(:tale_created_one),
        publications(:three),
        publications(:four),
        publications(:five)
      ]

      assert_equal(
        { hero: hero, left: side.first(2), right: side.last(2), side: side },
        home_tales_editorial_cards(hero, side)
      )
    end

    test 'home_tales_editorial_cards leaves the hero empty when no highlight exists' do
      tales = [
        publications(:tale_created_one),
        publications(:three),
        publications(:four)
      ]

      assert_equal(
        { hero: nil, left: [tales[0], tales[1]], right: [tales[2]], side: tales },
        home_tales_editorial_cards(nil, tales)
      )
    end

    test 'home_tales_editorial_cards orders side tales by recency before filling columns' do
      hero = publications(:tale_approved_one)
      newest = publications(:tale_created_one)
      middle = publications(:three)
      older = publications(:four)
      oldest = publications(:five)

      cards = home_tales_editorial_cards(hero, [oldest, middle, newest, older])

      assert_equal hero, cards[:hero]
      assert_equal [newest, middle], cards[:left]
      assert_equal [older, oldest], cards[:right]
    end

    test 'home_tales_editorial_cards excludes duplicate hero from side columns' do
      hero = publications(:tale_approved_one)
      side = [
        publications(:tale_created_one),
        publications(:three),
        publications(:four)
      ]

      cards = home_tales_editorial_cards(hero, [hero, *side])

      assert_equal [side.first, side.second], cards[:left]
      assert_equal [side.third], cards[:right]
    end

    test 'home_tales_editorial_cards returns empty slots for blank input' do
      assert_equal(
        { hero: nil, left: [], right: [], side: [] },
        home_tales_editorial_cards(nil, [])
      )
    end

    test 'tale_published_date formats created_at when the post was published immediately' do
      publication = Publication.new(created_at: Time.zone.parse('2026-06-25 10:00'))

      assert_equal '25 червень 2026', tale_published_date(publication)
    end

    test 'tale_published_date uses the publish time of a deferred sketch' do
      publication = Publication.new(
        created_at: Time.zone.parse('2026-10-19 18:00'),
        published_at: Time.zone.parse('2026-10-23 12:00')
      )

      assert_equal '23 жовтень 2026', tale_published_date(publication)
    end

    test 'home_tales_editorial_cards orders deferred tales by publication time' do
      hero = publications(:tale_approved_one)
      deferred = Publication.new(created_at: Time.zone.parse('2026-10-19'), published_at: Time.zone.parse('2026-10-23'))
      fresh = Publication.new(created_at: Time.zone.parse('2026-10-21'), published_at: Time.zone.parse('2026-10-21'))

      cards = home_tales_editorial_cards(hero, [fresh, deferred])

      assert_equal [deferred, fresh], cards[:left]
    end
  end
end
