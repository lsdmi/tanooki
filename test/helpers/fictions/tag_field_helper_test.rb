# frozen_string_literal: true

require 'test_helper'

module Fictions
  class TagFieldHelperTest < ActionView::TestCase
    include Fictions::TagFieldHelper

    test 'selected names are the saved tags, alphabetically' do
      fiction = fictions(:one)
      fiction.fiction_tags << [fiction_tags(:rebirth), fiction_tags(:litrpg)]

      assert_equal %w[ЛітРПГ Переродження], fiction_tag_selected_names(fiction)
    end

    test 'selected names prefer the submitted choice over the saved tags' do
      fiction = fictions(:one)
      fiction.fiction_tags << fiction_tags(:rebirth)
      fiction.tag_names = ['Нова']

      assert_equal ['Нова'], fiction_tag_selected_names(fiction)
    end

    test 'an empty submitted choice is respected, not replaced by the saved tags' do
      fiction = fictions(:one)
      fiction.fiction_tags << fiction_tags(:rebirth)
      fiction.tag_names = []

      assert_empty fiction_tag_selected_names(fiction)
    end

    test 'options list selected names first, then active tags, without case duplicates' do
      options = fiction_tag_option_names(%w[переродження Юрі])

      assert_equal %w[переродження Юрі ЛітРПГ], options
    end

    test 'options sort selected names and remaining active tags alphabetically, each group on its own' do
      FictionTag.create!(name: 'Аніме')
      options = fiction_tag_option_names(%w[Юрі Переродження])

      assert_equal %w[Переродження Юрі Аніме ЛітРПГ], options
    end
  end
end
