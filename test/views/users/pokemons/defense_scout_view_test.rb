# frozen_string_literal: true

require 'test_helper'

class DefenseScoutViewTest < ActionView::TestCase
  helper Pokemons::DexHelper, Pokemons::StatsHelper

  setup do
    @opponent = users(:user_two)
    @slot = user_pokemons(:two)
    @opponent.trainer_profile.update!(defense_team_ids: [@slot.id])
  end

  test 'collapses scout behind binoculars' do
    render partial: 'users/pokemons/defense_scout', locals: { opponent: @opponent }
    label = I18n.t('pokemons.teams.scout')

    assert_select 'details summary[aria-label=?][title=?] svg[aria-hidden=true]', label, label
    assert_select 'details ol[aria-label=?]', label
  end

  test 'shows type icons and labels without level text' do
    render partial: 'users/pokemons/defense_scout', locals: { opponent: @opponent }
    labels = @slot.pokemon.types.map(&:label)

    assert_includes rendered, labels.join(' · ')
    assert_includes rendered, "pokemon_types/#{@slot.pokemon.types.first.key}"
    assert_not_includes rendered, "р. #{@slot.current_level}"
  end
end
