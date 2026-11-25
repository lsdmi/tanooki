# frozen_string_literal: true

# What a fiction puts into the OpenSearch index and which fields a reader's query searches.
# Included before `searchkick`, so Searchkick keeps this search_data instead of defining its own.
module FictionSearch
  extend ActiveSupport::Concern

  # Tag names weigh least: a title match always ranks above a work that only carries the word as a tag.
  SEARCH_FIELDS = ['title^2', 'alternative_title', 'author', 'english_title', 'scanlators', 'tag_names^0.5'].freeze

  def search_data
    {
      author:, alternative_title:, english_title:, title:,
      scanlators: scanlators.pluck(:title).to_sentence,
      licensed: licensed?, active: true,
      content_rating: self.class.content_ratings.fetch(content_rating),
      genre_ids: fiction_genres.pluck(:genre_id), **tag_search_data
    }
  end

  private

  # Search sees the same tags readers do: hidden ones stay out of the index.
  def tag_search_data
    tags = fiction_tags.active.pluck(:id, :name)
    { fiction_tag_ids: tags.map(&:first), tag_names: tags.map(&:last) }
  end
end
