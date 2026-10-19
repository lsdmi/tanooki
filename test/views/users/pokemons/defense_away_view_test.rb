# frozen_string_literal: true

require 'test_helper'

class DefenseAwayViewTest < ActionView::TestCase
  helper Pokemons::DexHelper

  test 'renders the whisper when there is something to report' do
    report = Pokemons::DefenseAway::Report.new(1, 2)
    render partial: 'users/pokemons/defense_away', locals: { report: }

    assert_includes rendered, 'Поки вас не було'
    assert_includes rendered, '1 перемога'
    assert_includes rendered, '2 поразки'
  end

  test 'renders nothing when the report is empty' do
    render partial: 'users/pokemons/defense_away', locals: { report: Pokemons::DefenseAway::NONE }

    assert_equal '', rendered.strip
  end
end
