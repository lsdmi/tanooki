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
        home_tales_editorial_cards([hero], side)
      )
    end

    test 'home_tales_editorial_cards promotes first tale when no highlight exists' do
      tales = [
        publications(:tale_created_one),
        publications(:three),
        publications(:four)
      ]

      assert_equal(
        { hero: tales.first, left: [tales[1], tales[2]], right: [], side: [tales[1], tales[2]] },
        home_tales_editorial_cards([], tales)
      )
    end

    test 'home_tales_editorial_cards returns empty slots for blank input' do
      assert_equal(
        { hero: nil, left: [], right: [], side: [] },
        home_tales_editorial_cards([], [])
      )
    end

    test 'tale_published_date formats created_at in Ukrainian short form' do
      publication = publications(:tale_approved_one)

      travel_to Time.zone.parse('2026-07-14 12:00') do
        publication.update!(created_at: Time.zone.parse('2026-06-25 10:00'))

        assert_equal '25 червень 2026', tale_published_date(publication)
      end
    end
  end
end
