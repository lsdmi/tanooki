# frozen_string_literal: true

# Genres (top-level form) and FictionTags (themes, tropes) on a fiction.
module FictionTaxonomy
  extend ActiveSupport::Concern

  included do
    # Names submitted by the form; kept so a failed save can show the choice again (like genre_ids).
    attr_accessor :tag_names

    # Soft-delete runs destroy callbacks, so links go away on soft delete and
    # FictionTag#fictions_count only counts live fictions.
    has_many :fiction_genres, dependent: :destroy
    has_many :genres, through: :fiction_genres
    has_many :fiction_tag_links, dependent: :destroy
    has_many :fiction_tags, through: :fiction_tag_links
  end

  # Tags readers see: a hidden tag stays on the work (so a merge can still move it) but not on the page.
  # 18+ tags lead the list, the rest are alphabetical.
  def visible_fiction_tags
    fiction_tags.active.order(explicit: :desc, name: :asc).to_a
  end
end
