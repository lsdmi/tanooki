# frozen_string_literal: true

require 'test_helper'

class FictionTagTest < ActiveSupport::TestCase
  test 'fixture is valid' do
    assert_predicate fiction_tags(:rebirth), :valid?
  end

  test 'new tags are active and not explicit by default' do
    tag = FictionTag.create!(name: 'Академія магії')

    assert_predicate tag, :active?
    assert_not tag.explicit?
    assert_equal 0, tag.fictions_count
  end

  test 'normalizes name and builds a transliterated slug' do
    tag = FictionTag.create!(name: '  #пригода   у часі ')

    assert_equal 'пригода у часі', tag.name
    assert_equal 'pryhoda-u-chasi', tag.slug
  end

  test 'name must be present' do
    tag = FictionTag.new(name: '   ')

    assert_not tag.valid?
    assert_includes tag.errors.details[:name], { error: :blank }
  end

  test 'name must be at most 40 characters' do
    tag = FictionTag.new(name: 'а' * 41)

    assert_not tag.valid?
  end

  test 'name must produce a slug' do
    tag = FictionTag.new(name: '!!!')

    assert_not tag.valid?
    assert_includes tag.errors.details[:name], { error: :invalid }
  end

  test 'name is unique regardless of case' do
    tag = FictionTag.new(name: 'переродження')

    assert_not tag.valid?
    assert_includes tag.errors.details[:name].pluck(:error), :taken
  end

  test 'a duplicate name reports the taken error only once' do
    tag = FictionTag.new(name: 'переродження')
    tag.valid?

    assert_equal ['Такий теґ уже існує.'], tag.errors[:name]
  end

  test 'names that collapse to an existing slug are rejected' do
    FictionTag.create!(name: "пам'ять")
    tag = FictionTag.new(name: 'ПАМʼЯТЬ!')

    assert_not tag.valid?
    assert_includes tag.errors.details[:name].pluck(:error), :taken
  end

  test 'renaming keeps the slug stable' do
    tag = fiction_tags(:rebirth)
    tag.update!(name: 'Переродження в іншому світі')

    assert_equal 'pererodzhennia', tag.reload.slug
  end

  test 'finds by slug' do
    assert_equal fiction_tags(:litrpg), FictionTag.friendly.find('litrph')
  end

  test 'status scopes' do
    assert_includes FictionTag.active, fiction_tags(:rebirth)
    assert_includes FictionTag.hidden, fiction_tags(:yuri_hidden)
    assert_not_includes FictionTag.active, fiction_tags(:yuri_hidden)
  end

  test 'hiding a tag keeps its links and count but drops it from public lists' do
    tag = fiction_tags(:rebirth)
    fiction = fictions(:one)
    fiction.fiction_tags << tag

    tag.hidden!

    assert_equal [tag], fiction.reload.fiction_tags.to_a
    assert_empty fiction.fiction_tags.active
    assert_equal 1, tag.reload.fictions_count
  end

  test 'destroying a tag removes its links' do
    tag = fiction_tags(:rebirth)
    fictions(:one).fiction_tags << tag

    assert_difference -> { FictionTagLink.count }, -1 do
      tag.destroy
    end
  end
end
