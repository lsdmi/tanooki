# frozen_string_literal: true

require 'test_helper'

class FictionFormContentRatingTest < ActiveSupport::TestCase
  test 'saves each content rating band' do
    fiction = fictions(:one)

    %w[sixteen eighteen everyone].each do |band|
      assert rating_form(fiction, content_rating: band).save
      assert_equal band, fiction.reload.content_rating
    end
  end

  test 'rejects a content rating outside the three bands' do
    fiction = fictions(:one)

    assert_not rating_form(fiction, content_rating: 'twelve').save
    assert fiction.errors.of_kind?(:content_rating, :inclusion)
    assert_predicate fiction.reload, :content_rating_everyone?
  end

  private

  def rating_form(fiction, **params)
    FictionForm.new(fiction:, params: {
                      title: fiction.title,
                      author: fiction.author,
                      description: fiction.description,
                      expected_chapters: fiction.expected_chapters,
                      scanlator_ids: [1],
                      **params
                    })
  end
end
