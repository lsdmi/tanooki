# frozen_string_literal: true

require 'test_helper'

module Studio
  class TabContentTest < ActiveSupport::TestCase
    test 'normalize_tab_id falls back to blogs for unknown ids' do
      assert_equal 'blogs', Studio.normalize_tab_id('not-a-tab')
    end

    test 'tab_partial maps known tab ids to partial paths' do
      assert_equal 'studio/tabs/pokemons', Studio.tab_partial('pokemons')
      assert_equal 'studio/tabs/blogs', Studio.tab_partial('nope')
    end

    test 'call with pokemons tab assigns Pokemons::StudioTab' do
      user = users(:user_one)
      service = TabContent.new(user, 'pokemons', {})

      service.call

      assert_instance_of Pokemons::StudioTab, service.instance_variable_get(:@pokemon_show)
    end

    test 'call with blogs tab paginates publications' do
      user = users(:user_one)
      service = TabContent.new(user, 'blogs', { page: 1 })

      service.call

      assert_instance_of Pagy, service.instance_variable_get(:@pagy)

      assert_equal user.publications.order(created_at: :desc).limit(8).to_a,
                   service.instance_variable_get(:@publications).to_a
    end

    test 'call with bookshelves tab loads ordered bookshelves' do
      user = users(:user_one)
      service = TabContent.new(user, 'bookshelves', {})

      service.call

      assert_equal user.bookshelves.ordered.to_a, service.instance_variable_get(:@bookshelves).to_a
    end

    test 'call with profile tab loads avatars' do
      user = users(:user_one)
      service = TabContent.new(user, 'profile', {})

      service.call

      expected = Avatar.includes(:image_attachment).order(created_at: :desc)

      assert_equal expected.to_a, service.instance_variable_get(:@avatars).to_a
    end

    test 'call falls back to blogs when tab id is unknown' do
      user = users(:user_one)
      service = TabContent.new(user, 'not_a_real_tab', {})

      service.call

      assert_instance_of Pagy, service.instance_variable_get(:@pagy)
      assert_equal user.publications.order(created_at: :desc).limit(8).to_a,
                   service.instance_variable_get(:@publications).to_a
    end
  end
end
