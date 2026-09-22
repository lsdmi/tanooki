# frozen_string_literal: true

require 'test_helper'

# Wild catch is opt-in per controller; high-traffic reading/studio surfaces must not load it.
class WildPokemonChromeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'ApplicationController does not register a global pokemon_appearance filter' do
    filters = ApplicationController._process_action_callbacks.filter_map do |callback|
      callback.filter if callback.kind == :before
    end

    assert_not_includes filters, :pokemon_appearance
  end

  test 'guest fiction show skips wild catch' do
    assert_skips_wild_catch { get fiction_path(fictions(:one)) }
  end

  test 'signed-in fiction show skips wild catch' do
    sign_in users(:user_one)

    assert_skips_wild_catch { get fiction_path(fictions(:one)) }
  end

  test 'signed-in chapter show skips wild catch' do
    sign_in users(:user_one)

    assert_skips_wild_catch { get chapter_path(chapters(:one)) }
  end

  test 'signed-in studio skips wild catch' do
    sign_in users(:user_one)

    assert_skips_wild_catch { get studio_index_path }
  end

  test 'guest home may invoke wild catch' do
    called = false
    Pokemons::WildCatch.stub(:new, lambda { |**|
      called = true
      Object.new.tap { |o| o.define_singleton_method(:call) { nil } }
    }) do
      get root_path
    end

    assert_response :success
    assert called
  end

  private

  def assert_skips_wild_catch(&)
    Pokemons::WildCatch.stub(:new, ->(*) { raise 'wild catch should be skipped on this surface' }, &)

    assert_response :success
    assert_nil assigns(:wild_pokemon)
    assert_select 'turbo-frame#catch-pokemon', count: 0
  end
end
