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
      stamp_recency(side)

      assert_equal(
        { hero: hero, left: side.first(2), right: side.last(2), side: side },
        home_tales_editorial_cards(hero, side)
      )
    end

    test 'home_tales_editorial_cards promotes first tale when no highlight exists' do
      tales = [
        publications(:tale_created_one),
        publications(:three),
        publications(:four)
      ]
      stamp_recency(tales)

      assert_equal(
        { hero: tales.first, left: [tales[1], tales[2]], right: [], side: [tales[1], tales[2]] },
        home_tales_editorial_cards(nil, tales)
      )
    end

    test 'home_tales_editorial_cards orders side tales by recency before filling columns' do
      hero = publications(:tale_approved_one)
      newest = publications(:tale_created_one)
      middle = publications(:three)
      older = publications(:four)
      oldest = publications(:five)
      stamp_recency([newest, middle, older, oldest])

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
      stamp_recency(side)

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

    test 'tale_published_date formats created_at in Ukrainian short form' do
      publication = publications(:tale_approved_one)

      travel_to Time.zone.parse('2026-07-14 12:00') do
        publication.update_column(:created_at, Time.zone.parse('2026-06-25 10:00')) # rubocop:disable Rails/SkipsModelValidations

        assert_equal '25 червень 2026', tale_published_date(publication)
      end
    end

    private

    def stamp_recency(publications, base_time: Time.zone.parse('2026-07-15 12:00'))
      publications.each_with_index do |publication, index|
        publication.update_column(:created_at, base_time - index.days) # rubocop:disable Rails/SkipsModelValidations
      end
    end
  end
end
