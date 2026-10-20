# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class BattleOgImageTest < ActiveSupport::TestCase
    include PokemonBattleHelpers

    setup do
      @attacker = users(:user_one)
      @defender = users(:user_two)
      team = [{ 'id' => 1, 'character' => 'brave', 'battle_experience' => 10, 'types' => %w[fire],
                'pokemon_id' => pokemons(:four).id, 'base_hp' => 100, 'base_attack' => 80 }]
      @battle = create_pokemon_battle(attacker: @attacker, defender: @defender, winner: @attacker,
                                      attacker_team: team,
                                      defender_team: [team.first.merge('id' => 2,
                                                                       'pokemon_id' => pokemons(:five).id)])
    end

    test 'renders a PNG of the expected Open Graph size' do
      png = BattleOgImage.new(@battle).png
      image = Vips::Image.new_from_buffer(png, '')

      assert_operator png.bytesize, :>, 1_000
      assert_equal [BattleOgImage::WIDTH, BattleOgImage::HEIGHT], [image.width, image.height]
    end
  end
end
