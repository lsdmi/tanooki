# frozen_string_literal: true

require 'test_helper'

class FictionPresentationTest < ActiveSupport::TestCase
  setup do
    @fiction = fictions(:one)
    Rails.cache.delete("related-to-#{@fiction.slug}")
  end

  test 'related_fictions excludes current fiction and reuses cache' do
    fiction = Fiction.includes(:scanlators).find(@fiction.id)
    related = fiction.related_fictions.limit(3).to_a

    assert_not_includes related.map(&:id), fiction.id
    assert_equal related.map(&:id), fiction.related_fictions.limit(3).map(&:id)
    assert Rails.cache.exist?("related-to-#{fiction.slug}")
  end

  test 'related_fictions returns empty relation when fiction has no scanlators' do
    fiction = Fiction.new(title: 'Orphan', slug: 'orphan-related-test')

    fiction.stub(:scanlators, Scanlator.none) do
      assert_empty fiction.related_fictions
    end
  end
end
