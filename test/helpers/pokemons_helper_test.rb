# frozen_string_literal: true

require 'test_helper'

class PokemonsHelperTest < ActionView::TestCase
  include PokemonsHelper

  test 'dex_title should return the correct title for case 0' do
    title = dex_title(0)
    assert_equal 'Чемпіон', title
  end

  test 'dex_title should return the correct title for cases 1..4' do
    (1..4).each do |index|
      title = dex_title(index)
      assert_equal 'Елітна четвірка', title
    end
  end

  test 'dex_title should return the correct title for cases 5..10' do
    (5..10).each do |index|
      title = dex_title(index)
      assert_equal 'Тренер', title
    end
  end

  test 'dex_title should return nil for negative or 999' do
    title = dex_title(-1)
    assert_nil title
  end
end
