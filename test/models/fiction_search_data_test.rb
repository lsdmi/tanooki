# frozen_string_literal: true

require 'test_helper'

class FictionSearchDataTest < ActiveSupport::TestCase
  test 'search_data indexes the rating integer and genre ids' do
    data = fictions(:one).search_data

    assert_equal 0, data.fetch(:content_rating)
    assert_equal [genres(:one).id], data.fetch(:genre_ids)
  end

  test 'search_data indexes active tags and leaves hidden ones out' do
    fiction = fictions(:one)
    active = fiction_tags(:rebirth)
    fiction.fiction_tags << [active, fiction_tags(:yuri_hidden)]

    data = fiction.search_data

    assert_equal [active.id], data.fetch(:fiction_tag_ids)
    assert_equal [active.name], data.fetch(:tag_names)
  end

  test 'search_data has empty tag lists for a work without tags' do
    data = fictions(:two).search_data

    assert_equal [[], []], data.values_at(:fiction_tag_ids, :tag_names)
  end

  test 'fiction search ranks tag names below every other field' do
    boosts = Fiction::SEARCH_FIELDS.to_h { |field| field.split('^').then { |name, boost| [name, (boost || 1).to_f] } }

    assert_operator boosts.fetch('tag_names'), :<, boosts.except('tag_names').values.min
  end
end
