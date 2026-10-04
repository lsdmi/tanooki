# frozen_string_literal: true

require 'test_helper'

class FictionsChapterGroupPagingTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @fiction = fictions(:one)
    (3..25).each do |number|
      Chapter.create!(fiction: @fiction, user: users(:user_one), title: "Chapter #{number}", number:,
                      content: 'x' * 500, scanlator_ids: [scanlators(:one).id])
    end
  end

  test 'the open group shows the first page with no inner scroll' do
    get fiction_url(@fiction)

    assert_select '#chapters-list [data-controller="chapter-group-pager"] > ul > li', count: 20
    assert_select '#chapters-list .accordion-content.max-h-96', count: 0
  end

  test 'when the rest fits in one page the footer offers only that page' do
    get fiction_url(@fiction)

    footer = '#chapters-list [data-chapter-group-pager-target="footer"]'

    assert_select "#{footer} [data-chapter-group-pager-target='moreLabel']", text: 'Показати ще 5'
    assert_select "#{footer} [data-chapter-group-pager-target='remaining'].hidden", text: 'ще 5 розділів'
    assert_select "#{footer} [data-chapter-group-pager-target='all'].hidden"
  end

  test 'a long remainder adds the count and «Показати всі»' do
    get chapter_section_fiction_path(@fiction, section: 'r-1-100', order: 'asc', limit: 2)

    assert_select '[data-chapter-group-pager-target="moreLabel"]', text: 'Показати ще 20'
    assert_select '[data-chapter-group-pager-target="remaining"]:not(.hidden)', text: 'ще 23 розділи'
    assert_select '[data-chapter-group-pager-target="all"]:not(.hidden)', text: 'Показати всі'
  end

  test 'the first page request returns the group body sized by limit' do
    get chapter_section_fiction_path(@fiction, section: 'r-1-100', order: 'asc', limit: 10)

    assert_select '[data-controller="chapter-group-pager"][data-chapter-group-pager-total-value="25"] > ul > li',
                  count: 10
  end

  test 'a next page request returns only the rows after the offset' do
    get chapter_section_fiction_path(@fiction, section: 'r-1-100', order: 'asc', offset: 20, limit: 20)

    assert_equal (21..25).map { |number| chapter_path(@fiction.chapters.find_by!(number:)) },
                 css_select('li a[href^="/chapters/"]').pluck('href')
    assert_select '[data-controller="chapter-group-pager"]', count: 0
  end

  test '«Показати всі» loads the rest of the group' do
    get chapter_section_fiction_path(@fiction, section: 'r-1-100', order: 'desc', offset: 10, limit: 'all')

    assert_select 'li', count: 15
  end

  test 'the reader drawer still gets the whole group' do
    get chapter_section_fiction_path(@fiction, section: 'r-1-100', order: 'asc', reader_drawer: true, limit: 10)

    assert_select 'ul > li', count: 25
    assert_select '[data-controller="chapter-group-pager"]', count: 0
  end

  test 'lazy groups wait with skeleton rows' do
    Chapter.create!(fiction: @fiction, user: users(:user_one), title: 'Next range', number: 101,
                    content: 'x' * 500, scanlator_ids: [scanlators(:one).id])
    get fiction_url(@fiction)

    lazy = '#chapters-list [data-chapter-section-url][data-chapter-section-page-size="20"]' \
           '[data-chapter-section-mobile-page-size="10"]'

    assert_select "#{lazy} ul.chapter-section-placeholder[aria-busy=true] > li.animate-pulse", count: 4
  end
end
