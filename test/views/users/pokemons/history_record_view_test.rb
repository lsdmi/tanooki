# frozen_string_literal: true

require 'test_helper'

class HistoryRecordViewTest < ActionView::TestCase
  include PokemonBattleHelpers

  helper Pokemons::DexHelper, Layout::TurboDriveHelper

  setup do
    @attacker = users(:user_one)
    @defender = users(:user_two)
    @battle = create_pokemon_battle(attacker: @attacker, defender: @defender, winner: @attacker)
  end

  test 'links the shareable battle page from history' do
    render partial: 'users/pokemons/history_record', locals: { battle: @battle }
    label = I18n.t('pokemons.battle.share_link')

    assert_select 'a[href=?][aria-label=?][title=?] svg[aria-hidden=true]',
                  pokemon_battle_path(@battle), label, label
  end
end
