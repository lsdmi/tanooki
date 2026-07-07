# frozen_string_literal: true

require 'test_helper'

module Adsense
  class PlacementsHelperTest < ActionView::TestCase
    include PlacementsHelper

    test 'adsense_slot_live? requires allowed adsense and a configured slot id' do
      define_singleton_method(:adsense_allowed?) { true }

      assert_not adsense_slot_live?(:fiction_alphabetical)
      assert_nil adsense_slot_id(:fiction_alphabetical)
    end

    test 'adsense_slot_live? is false when adsense is disabled' do
      define_singleton_method(:adsense_allowed?) { false }

      assert_not adsense_slot_live?(:chapter_reader_top)
    end
  end
end
