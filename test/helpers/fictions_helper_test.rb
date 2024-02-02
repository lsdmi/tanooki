# frozen_string_literal: true

class FictionsHelperTest < ActionView::TestCase
  include FictionsHelper

  test 'returns proper message for fiction without translator' do
    fiction = Fiction.new(author: 'Jane Smith')
    expected_output = 'Оригінальна робота <strong>Jane Smith</strong>'
    assert_equal expected_output, fiction_author(fiction)
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
