# frozen_string_literal: true

require 'test_helper'

class FictionsIndexGenreSpotlightTest < ActionDispatch::IntegrationTest
  setup do
    @fantasy = genres(:one)
    @history = genres(:two)
    @shared = fictions(:one)
    @history_only = fictions(:two)
    @shared.genres << @fantasy unless @shared.genres.exists?(@fantasy.id)
    @shared.genres << @history unless @shared.genres.exists?(@history.id)
    @history_only.genres << @history unless @history_only.genres.exists?(@history.id)
    set_public_time(chapters(:two), 1.hour.ago)
    set_public_time(chapters(:three), 2.hours.ago)
    Rails.cache.delete(Fictions::IndexGenreSpotlight.cache_key)
  end

  test 'renders genres after fanfictions' do
    genres(:fanfiction).tap do |genre|
      @shared.genres << genre unless @shared.genres.exists?(genre.id)
    end
    Rails.cache.delete(['fiction_index/fanfiction_ids', Fictions::IndexVariablesManager::FANFICTION_INDEX_CARDS])

    get fictions_path

    assert_operator response.body.index('fictions-index-genres'),
                    :>,
                    response.body.index('fictions-index-fanfictions')
  end

  test 'header names genres and links to the alphabetical catalog' do
    get fictions_path

    assert_select '#fictions-index-genres', text: 'Жанри'
    assert_select "[aria-labelledby='fictions-index-genres'] a[href='#{alphabetical_fictions_path}']",
                  text: /Більше/
  end

  test 'lists genre tiles with cover stacks and work counts' do
    get fictions_path

    assert_select '[aria-labelledby="fictions-index-genres"] a[href=?]',
                  fiction_genre_fictions_path(@fantasy),
                  text: /#{@fantasy.name}/
    assert_select '[aria-labelledby="fictions-index-genres"]',
                  text: /творів/
  end

  test 'hides the section when no ranked genres exist' do
    FictionGenre.where(genre_id: [@fantasy.id, @history.id, genres(:three).id]).delete_all
    Rails.cache.delete(Fictions::IndexGenreSpotlight.cache_key)

    get fictions_path

    assert_select '#fictions-index-genres', count: 0
  end

  private

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
