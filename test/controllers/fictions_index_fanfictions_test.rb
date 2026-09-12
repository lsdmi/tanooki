# frozen_string_literal: true

require 'test_helper'

class FictionsIndexFanfictionsTest < ActionDispatch::IntegrationTest
  setup do
    @genre = genres(:fanfiction)
    @older = fictions(:one)
    @newer = fictions(:two)
    [@older, @newer].each do |fiction|
      fiction.genres << @genre unless fiction.genres.exists?(@genre.id)
    end
    Rails.cache.delete(['fiction_index/fanfiction_ids', Fictions::IndexVariablesManager::FANFICTION_INDEX_CARDS])
  end

  test 'renders fanfictions after originals when both are present' do
    original = genres(:original)
    [@older, @newer].each do |fiction|
      fiction.genres << original unless fiction.genres.exists?(original.id)
    end
    Rails.cache.delete(['fiction_index/originals_ids', Fictions::IndexVariablesManager::ORIGINALS_INDEX_CARDS])

    get fictions_path

    assert_operator response.body.index('fictions-index-fanfictions'),
                    :>,
                    response.body.index('fictions-index-originals')
  end

  test 'header names fanfiction and links to the genre hub' do
    get fictions_path

    assert_select '#fictions-index-fanfictions', text: 'Фанфіки'
    assert_select "[aria-labelledby='fictions-index-fanfictions'] a[href='#{fiction_genre_fictions_path(Genre::FANFICTION_SLUG)}']",
                  text: /Більше/
  end

  test 'reuses the popular ranobe card strip without ranks' do
    get fictions_path

    assert_select '[aria-labelledby="fictions-index-fanfictions"] [aria-label="Фанфіки"] article',
                  count: 2
    assert_select '[aria-labelledby="fictions-index-fanfictions"] article > a > span', count: 0
  end

  test 'cards credit the scanlator between title and genres' do
    get fictions_path

    creator = scanlators(:one)

    assert_select "[aria-labelledby='fictions-index-fanfictions'] a[href='#{scanlator_path(creator)}']",
                  text: creator.title
    assert_select '[aria-labelledby="fictions-index-fanfictions"] article .pb-2 a.border', minimum: 1
  end

  test 'orders fanfictions by latest released chapter in the strip' do
    get fictions_path

    titles = css_select('[aria-labelledby="fictions-index-fanfictions"] article .font-semibold a').map(&:text)

    assert_equal [@newer.title, @older.title], titles
  end

  test 'hides the section when no fanfiction fictions exist' do
    FictionGenre.where(genre_id: @genre.id).delete_all
    Rails.cache.delete(['fiction_index/fanfiction_ids', Fictions::IndexVariablesManager::FANFICTION_INDEX_CARDS])

    get fictions_path

    assert_select '#fictions-index-fanfictions', count: 0
  end
end
