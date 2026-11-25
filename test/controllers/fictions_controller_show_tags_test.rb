# frozen_string_literal: true

require 'test_helper'

# The «Теґи» block of the About tab: active tags only, 18+ ones marked, no block when empty.
class FictionsControllerShowTagsTest < ActionDispatch::IntegrationTest
  BLOCK = 'section[aria-label="Теґи"]'

  setup do
    @fiction = fictions(:one)
  end

  test 'a work with no genres and no tags opens straight on the description, with no empty wrapper' do
    @fiction.genres = []

    get fiction_url(@fiction)

    column = response.parsed_body.at_css('#fiction-description-title').ancestors('section').first.parent

    assert_equal 'section', column.element_children.first.name
  end

  test 'a work without tags has no block' do
    get fiction_url(@fiction)

    assert_response :success
    assert_select BLOCK, count: 0
  end

  test 'shows active tags and leaves a hidden one off the page' do
    @fiction.fiction_tags << [fiction_tags(:rebirth), fiction_tags(:yuri_hidden)]

    get fiction_url(@fiction)

    assert_select "#{BLOCK} span", text: '#Переродження'
    assert_select BLOCK, text: /Юрі/, count: 0
  end

  test 'each tag links to its catalogue filter, with no chip styling' do
    @fiction.fiction_tags << fiction_tags(:rebirth)

    get fiction_url(@fiction)

    assert_select "#{BLOCK} a[href=?]", alphabetical_fictions_path(tags: ['pererodzhennia']), text: '#Переродження'
    assert_select "#{BLOCK} span.border", count: 0
  end

  test 'an 18+ tag is marked with the warning icon and listed first' do
    adult = FictionTag.create!(name: 'Омегаверс', explicit: true)
    @fiction.fiction_tags << [fiction_tags(:rebirth), adult]

    get fiction_url(@fiction)

    assert_select "#{BLOCK} span.text-status-danger-solid svg"
    assert_select "#{BLOCK} span.text-status-danger-solid", text: /#Омегаверс/
  end

  test 'sits below the genres, not instead of them' do
    @fiction.fiction_tags << fiction_tags(:rebirth)

    get fiction_url(@fiction)

    assert_select "#{BLOCK} a[href*='/genres/']", count: 0
    assert_select 'a[href*="/genres/"]'
  end
end
