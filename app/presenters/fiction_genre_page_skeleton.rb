# frozen_string_literal: true

# Placeholder + DB-backed content for `fictions/genres#show`.
class FictionGenrePageSkeleton
  include Rails.application.routes.url_helpers
  include FictionGenrePageNewReleases

  def initialize(genre)
    @genre = genre
  end

  attr_reader :genre

  def breadcrumbs
    [
      { label: 'Головна', path: '/' },
      { label: 'Ранобе', path: fictions_path },
      { label: @genre.name, path: nil }
    ]
  end

  def fictions_count
    @fictions_count ||= @genre.fictions.count
  end

  def found_fictions_badge_text
    n = fictions_count
    formatted = ActionController::Base.helpers.number_with_delimiter(n)
    "#{formatted} творів"
  end

  def new_releases_title
    'Популярне ранобе'
  end

  def new_releases_subtitle
    "Найкраще у жанрі «#{@genre.name}», відібране за переглядами та оцінками читачів."
  end

  def new_releases_featured
    new_releases_ranked_cards.first(2)
  end

  def new_releases_thumbs
    new_releases_ranked_cards.drop(2).first(6)
  end

  def recommended_title
    'Нові Релізи'
  end

  def recommended_subtitle
    "Нещодавні оновлення в жанрі «#{@genre.name}»."
  end

  def popular_top_eight_fiction_ids
    @popular_top_eight_fiction_ids ||= Fictions::Ranker.most_read_fiction_ids_for_genre(@genre, limit: 8)
  end

  private

  def helpers
    @helpers ||= ApplicationController.helpers
  end
end
