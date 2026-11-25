# frozen_string_literal: true

require 'test_helper'

class FictionListQueryBuilderTagsTest < ActiveSupport::TestCase
  setup do
    @rebirth = fiction_tags(:rebirth)
    @litrpg = fiction_tags(:litrpg)
    @one = fictions(:one)
    @two = fictions(:two)
  end

  test 'one tag keeps only the works that carry it' do
    @one.fiction_tags << @rebirth

    ids = FictionListQueryBuilder.new(Fiction.all, tags: [@rebirth.slug]).call.map(&:id)

    assert_equal [@one.id], ids
  end

  test 'several tags keep only the works that carry all of them' do
    @one.fiction_tags << [@rebirth, @litrpg]
    @two.fiction_tags << @rebirth

    ids = FictionListQueryBuilder.new(Fiction.all, tags: [@rebirth.slug, @litrpg.slug]).call.map(&:id)

    assert_equal [@one.id], ids
  end

  test 'an unknown tag matches nothing' do
    @one.fiction_tags << @rebirth

    ids = FictionListQueryBuilder.new(Fiction.all, tags: [@rebirth.slug, 'no-such-tag']).call.map(&:id)

    assert_empty ids
  end

  test 'a tag and a genre narrow the list together' do
    @one.fiction_tags << @rebirth
    @two.fiction_tags << @rebirth
    FictionGenre.create!(fiction: @one, genre: genres(:one))

    ids = FictionListQueryBuilder.new(Fiction.all, tags: [@rebirth.slug], genre: genres(:one).id).call.map(&:id)

    assert_equal [@one.id], ids
  end

  test 'an adult tag matches only when adult tags are allowed' do
    adult = FictionTag.create!(name: 'Омегаверс', explicit: true)
    @one.fiction_tags << adult

    assert_empty FictionListQueryBuilder.new(Fiction.all, tags: [adult.slug]).call
    ids = FictionListQueryBuilder.new(Fiction.all, { tags: [adult.slug] }, true).call.map(&:id)

    assert_equal [@one.id], ids
  end

  test 'a hidden tag matches nothing' do
    hidden = fiction_tags(:yuri_hidden)
    @one.fiction_tags << hidden

    assert_empty FictionListQueryBuilder.new(Fiction.all, tags: [hidden.slug]).call
  end
end
