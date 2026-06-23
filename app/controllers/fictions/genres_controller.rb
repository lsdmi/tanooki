# frozen_string_literal: true

module Fictions
  # Per-genre hub: hero, showcase carousel, new releases, and paginated “recommended” list.
  class GenresController < ApplicationController
    helper Library::ChapterCatalogHelper

    before_action :set_genre
    before_action :pokemon_appearance, only: [:show]

    def show
      @skeleton = FictionGenrePageSkeleton.new(@genre)
      @index_presenter = FictionIndexPresenter.new
      assign_genre_showcase_carousel
      assign_genre_recent_releases
      render_genre_recent_releases_frame? && return
    end

    private

    def render_genre_recent_releases_frame?
      return false unless turbo_frame_request_id == 'genre-recent-fictions-page' && @genre_recent_fictions.any?

      render partial: 'fictions/genres/genre_recent_fictions_frame',
             locals: {
               skeleton: @skeleton,
               pagy: @pagy_genre_recent,
               fictions: @genre_recent_fictions,
               released_by_fiction: @genre_recent_released_counts
             }
      true
    end

    def set_genre
      @genre = Genre.resolve_from_slug_param(params[:slug])
      raise ActiveRecord::RecordNotFound unless @genre
    end

    # Same partial as fictions#index; carousel uses IndexVariablesManager.showcase_for_genre (aligned with showcase).
    def assign_genre_showcase_carousel
      in_genre = @genre.fiction_ids.to_set
      @genre_showcase = Fictions::IndexVariablesManager.showcase_for_genre(@genre)
      @genre_showcase_popular_ids = @index_presenter.carousel_popular_novelty_ids & in_genre
      @genre_showcase_top_ids = @index_presenter.carousel_most_read_ids & in_genre
      @genre_showcase_latest_ids = @index_presenter.carousel_latest_update_ids & in_genre
    end

    def assign_genre_recent_releases
      exclude_ids = @skeleton.popular_top_eight_fiction_ids
      scope = Fictions::IndexVariablesManager.genre_recent_updates_excluding(@genre, exclude_ids: exclude_ids)
      @pagy_genre_recent, @genre_recent_fictions = pagy(scope, limit: 12)
      ids = @genre_recent_fictions.map(&:id)
      @genre_recent_released_counts =
        if ids.empty?
          {}
        else
          Chapter.where(fiction_id: ids).merge(Chapter.released).group(:fiction_id).count
        end
    end
  end
end
