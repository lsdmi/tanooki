# frozen_string_literal: true

class FictionsHelperTest < ActionView::TestCase
  include FictionsHelper

  test 'returns proper message for fiction with translator' do
    fiction = Fiction.new(translator: 'John Doe')
    expected_output = 'Перекладач: <strong>John Doe</strong>'
    assert_equal expected_output, fiction_author(fiction)
  end

  test 'returns proper message for fiction without translator' do
    fiction = Fiction.new(author: 'Jane Smith')
    expected_output = 'Оригінальна робота <strong>Jane Smith</strong>'
    assert_equal expected_output, fiction_author(fiction)
  end

  test 'chapter_item_theme returns black theme' do
    theme = chapter_item_theme(:black)
    assert_equal(
      { icon: 'text-gray-500', text: 'text-gray-500', title: 'text-gray-900',
        title_hover: 'hover:text-gray-600' }, theme
    )
  end

  test 'chapter_item_theme returns gray theme' do
    theme = chapter_item_theme(:gray)
    assert_equal(
      { icon: 'text-gray-400', text: 'text-gray-400', title: 'text-gray-500',
        title_hover: 'hover:text-gray-800' }, theme
    )
  end

  test 'chapter_item_theme returns green theme' do
    theme = chapter_item_theme(:green)
    assert_equal(
      { icon: 'text-emerald-700', text: 'text-emerald-700', title: 'text-emerald-900',
        title_hover: 'hover:text-emerald-600' }, theme
    )
  end

  test 'column_selector returns col-span-5' do
    selector = column_selector(5)
    assert_equal('col-span-5', selector)
  end

  test 'column_selector returns col-span-4' do
    selector = column_selector(4)
    assert_equal('col-span-4', selector)
  end

  test 'column_selector returns col-span-3' do
    selector = column_selector(3)
    assert_equal('col-span-3', selector)
  end

  test 'column_selector returns col-span-2' do
    selector = column_selector(2)
    assert_equal('col-span-2', selector)
  end
end
