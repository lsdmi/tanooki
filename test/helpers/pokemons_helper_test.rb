# frozen_string_literal: true

require 'test_helper'

class PokemonsHelperTest < ActionView::TestCase
  include PokemonsHelper

  test 'dex_title should return the correct title for case 0' do
    title = dex_title(4)
    assert_equal 'Початківець (Ранг E)', title
  end

  test 'dex_title should return the correct title for case 21' do
    title = dex_title(41)
    assert_equal 'Школяр (Ранг D)', title
  end

  test 'dex_title should return the correct title for case 41' do
    title = dex_title(59)
    assert_equal 'Тренер (Ранг C)', title
  end

  test 'dex_title should return the correct title for case 61' do
    title = dex_title(83)
    assert_equal 'Висхідна зірка (Ранг B)', title
  end

  test 'dex_title should return the correct title for case 81' do
    title = dex_title(93)
    assert_equal 'Майстер (Ранг A)', title
  end

  test 'dex_title should return the correct title for case 91' do
    title = dex_title(99)
    assert_equal 'Чемпіон (Ранг S)', title
  end
end
