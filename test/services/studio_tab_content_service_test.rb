# frozen_string_literal: true

require 'test_helper'

class StudioTabContentServiceTest < ActiveSupport::TestCase
  test 'call with pokemons tab assigns PokemonShow' do
    user = users(:user_one)
    service = StudioTabContentService.new(user, 'pokemons', {})

    service.call

    assert_instance_of PokemonShow, service.instance_variable_get(:@pokemon_show)
  end

  test 'call with blogs tab paginates publications' do
    user = users(:user_one)
    service = StudioTabContentService.new(user, 'blogs', { page: 1 })

    service.call

    assert_instance_of Pagy, service.instance_variable_get(:@pagy)
    assert_equal user.publications.order(created_at: :desc).limit(8).to_a,
                 service.instance_variable_get(:@publications).to_a
  end

  test 'call with bookshelves tab loads ordered bookshelves' do
    user = users(:user_one)
    service = StudioTabContentService.new(user, 'bookshelves', {})

    service.call

    assert_equal user.bookshelves.ordered.to_a, service.instance_variable_get(:@bookshelves).to_a
  end

  test 'call with profile tab loads avatars' do
    user = users(:user_one)
    service = StudioTabContentService.new(user, 'profile', {})

    service.call

    expected = Avatar.includes(:image_attachment).order(created_at: :desc)
    assert_equal expected.to_a, service.instance_variable_get(:@avatars).to_a
  end

  test 'call raises when tab has no content loader' do
    service = StudioTabContentService.new(users(:user_one), 'not_a_real_tab', {})

    assert_raises(NoMethodError) { service.call }
  end
end
