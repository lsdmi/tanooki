# frozen_string_literal: true

require 'test_helper'

class FictionVisibleTagsTest < ActiveSupport::TestCase
  setup do
    @fiction = fictions(:one)
  end

  test 'a hidden tag stays on the work but is not shown' do
    @fiction.fiction_tags << [fiction_tags(:rebirth), fiction_tags(:yuri_hidden)]

    assert_equal [fiction_tags(:rebirth)], @fiction.visible_fiction_tags
    assert_includes @fiction.fiction_tags, fiction_tags(:yuri_hidden)
  end

  test '18+ tags lead, then alphabetical' do
    adult = FictionTag.create!(name: 'Омегаверс', explicit: true)
    @fiction.fiction_tags << [fiction_tags(:rebirth), fiction_tags(:litrpg), adult]

    assert_equal %w[Омегаверс ЛітРПГ Переродження], @fiction.visible_fiction_tags.map(&:name)
  end

  test 'a work with no tags has none' do
    assert_empty @fiction.visible_fiction_tags
  end
end
