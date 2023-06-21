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
end
