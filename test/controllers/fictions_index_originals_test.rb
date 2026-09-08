# frozen_string_literal: true

require 'test_helper'

class FictionsIndexOriginalsTest < ActionDispatch::IntegrationTest
  setup do
    @genre = genres(:original)
    @older = fictions(:one)
    @newer = fictions(:two)
    [@older, @newer].each do |fiction|
      fiction.genres << @genre unless fiction.genres.exists?(@genre.id)
    end
    Rails.cache.delete(['fiction_index/originals_ids', Fictions::IndexVariablesManager::ORIGINALS_INDEX_CARDS])
  end

  test 'renders originals after popular ranobe' do
    get fictions_path

    assert_operator response.body.index('fictions-index-originals'),
                    :>,
                    response.body.index('fictions-index-popular-ranobe')
  end

  test 'section is a full-width band with the writer background' do
    get fictions_path

    assert_select 'section[aria-labelledby="fictions-index-originals"].w-full', count: 1
    assert_select '.fictions-originals.w-full.bg-blend-multiply[style*="writer"]', count: 1
    assert_select '.fictions-originals .max-w-\\[1300px\\]', count: 1
  end

  test 'header copy names Ukrainian authors' do
    get fictions_path

    assert_select '#fictions-index-originals', text: /Українські\s+Автори/
    assert_select '#fictions-index-originals span', text: 'Українські'
    assert_select '[aria-labelledby="fictions-index-originals"] p',
                  text: 'Вигадки, що зродилися тут-таки, на Баці'
  end

  test 'more link points at the original genre' do
    get fictions_path

    assert_select "[aria-labelledby='fictions-index-originals'] a[href='#{fiction_genre_fictions_path(Genre::ORIGINAL_SLUG)}']",
                  text: /Більше/
  end

  test 'lists every original with a Ukrainian flag badge' do
    get fictions_path

    assert_select '[aria-labelledby="fictions-index-originals"] [aria-label="Українські Автори"] article',
                  count: 2
    assert_select '[aria-labelledby="fictions-index-originals"] article svg[aria-label="Українське"]', count: 2
  end

  test 'each card includes a scattered vyshyvanka ornament' do
    get fictions_path

    assert_select '[aria-labelledby="fictions-index-originals"] article svg[aria-hidden="true"] use',
                  minimum: 8
  end

  test 'each card pairs a blurred backdrop with the cover thumbnail' do
    get fictions_path

    assert_select '[aria-labelledby="fictions-index-originals"] article img[aria-hidden="true"].blur-sm', count: 2
    assert_select '[aria-labelledby="fictions-index-originals"] article img[alt=?]', @newer.title
  end

  test 'cards credit the scanlator and show a synopsis' do
    get fictions_path

    creator = scanlators(:one)

    assert_select "[aria-labelledby='fictions-index-originals'] a[href='#{scanlator_path(creator)}']",
                  text: creator.title
    assert_select '[aria-labelledby="fictions-index-originals"] article', text: /#{@newer.description}/
  end

  test 'cards omit the rating and view stat overlays' do
    get fictions_path

    assert_select '[aria-labelledby="fictions-index-originals"] article .bg-black\\/40', count: 0
  end

  test 'orders originals by latest released chapter' do
    expected = Fictions::IndexVariablesManager.originals.to_a

    assert_equal [@newer.id, @older.id], expected.map(&:id)

    get fictions_path

    titles = css_select('[aria-labelledby="fictions-index-originals"] article .font-semibold a').map(&:text)

    assert_equal expected.map(&:title), titles
  end

  test 'hides the section when no original fictions exist' do
    FictionGenre.where(genre_id: @genre.id).delete_all
    Rails.cache.delete(['fiction_index/originals_ids', Fictions::IndexVariablesManager::ORIGINALS_INDEX_CARDS])

    get fictions_path

    assert_select '#fictions-index-originals', count: 0
  end

  test 'strip is capped at the configured originals count' do
    get fictions_path

    assert_select '[aria-labelledby="fictions-index-originals"] [aria-label="Українські Автори"] article',
                  maximum: Fictions::IndexVariablesManager::ORIGINALS_INDEX_CARDS
  end
end
