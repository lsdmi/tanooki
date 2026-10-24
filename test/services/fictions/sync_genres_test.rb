# frozen_string_literal: true

require 'test_helper'

module Fictions
  class SyncGenresTest < ActiveSupport::TestCase
    test 'touch the fiction when genres change so search picks up genre ids' do
      fiction = fictions(:one)
      stamp = fiction.updated_at

      travel 1.minute do
        SyncGenres.new([genres(:two).id.to_s], fiction).call
      end

      assert_operator fiction.reload.updated_at, :>, stamp
      assert_equal [genres(:two).id], fiction.fiction_genres.pluck(:genre_id)
    end

    test 'an unchanged genre list does not touch the fiction' do
      fiction = fictions(:one)
      stamp = fiction.updated_at

      SyncGenres.new([genres(:one).id.to_s], fiction).call

      assert_equal stamp, fiction.reload.updated_at
    end
  end
end
