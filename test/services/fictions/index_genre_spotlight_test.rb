# frozen_string_literal: true

require 'test_helper'

module Fictions
  class IndexGenreSpotlightTest < ActiveSupport::TestCase
    setup do
      @fantasy = genres(:one)
      @history = genres(:two)
      @shared = fictions(:one)
      @history_only = fictions(:two)
      FictionGenre.where(genre_id: [@fantasy.id, @history.id, genres(:three).id]).delete_all
      Rails.cache.delete(IndexGenreSpotlight.cache_key)
    end

    test 'orders genres by latest released chapter activity' do
      attach_genre(@history_only, @fantasy)
      attach_genre(@shared, @history)
      set_public_time(chapters(:three), 1.hour.ago)
      set_public_time(chapters(:two), 3.hours.ago)

      entries = IndexGenreSpotlight.call

      assert_equal([@fantasy.id, @history.id], entries.map { |entry| entry.genre.id })
    end

    test 'keeps a shared fiction only in the earlier genre cover set' do
      attach_genre(@shared, @fantasy)
      attach_genre(@shared, @history)
      attach_genre(@history_only, @history)
      set_public_time(chapters(:two), 1.hour.ago)
      set_public_time(chapters(:three), 2.hours.ago)

      entries = IndexGenreSpotlight.call
      fantasy_entry = entries.find { |entry| entry.genre.id == @fantasy.id }
      history_entry = entries.find { |entry| entry.genre.id == @history.id }

      assert_equal [@shared.id], fantasy_entry.fictions.map(&:id)
      assert_equal [@history_only.id], history_entry.fictions.map(&:id)
    end

    test 'excludes original and fanfiction genres' do
      original = genres(:original)
      fanfiction = genres(:fanfiction)
      attach_genre(@shared, original)
      attach_genre(@history_only, fanfiction)
      set_public_time(chapters(:two), 10.minutes.ago)
      set_public_time(chapters(:three), 5.minutes.ago)

      entry_ids = IndexGenreSpotlight.call.map { |entry| entry.genre.id }

      assert_not_includes entry_ids, original.id
      assert_not_includes entry_ids, fanfiction.id
    end

    test 'uses cached payload after the first fetch' do
      attach_genre(@shared, @fantasy)
      set_public_time(chapters(:two), 1.hour.ago)

      IndexGenreSpotlight.call

      IndexGenreSpotlight.stub(:payload_from_db, -> { raise 'cache miss' }) do
        assert_nothing_raised { IndexGenreSpotlight.call }
      end
    end

    private

    def attach_genre(fiction, genre)
      fiction.genres << genre unless fiction.genres.exists?(genre.id)
    end

    def set_public_time(chapter, time)
      attrs = {
        created_at: time,
        published_at: nil,
        scanlator_ids: chapter.scanlators.ids.presence || [scanlators(:one).id]
      }
      attrs[:content] = ('a' * 500) if chapter.content.blank? ||
                                       chapter.content.body.to_plain_text.length < 500
      chapter.update!(attrs)
    end
  end
end
