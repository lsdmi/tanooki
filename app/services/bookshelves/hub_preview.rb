# frozen_string_literal: true

module Bookshelves
  # Hub cards: popular strip + decorate helpers for paginated recent rows.
  class HubPreview
    # Focus band: one row of four equal cards.
    POPULAR_LIMIT = 4
    RECENT_PER_PAGE = 8
    COVERS = 3
    TOP_GENRES = 3

    Entry = Data.define(:bookshelf, :covers, :fictions_count, :top_genres, :max_content_rating)

    def self.popular(viewer: nil, filter: nil)
      new(viewer:, filter:).popular
    end

    # IDs only — turbo-frame recent pages need focus exclusions without decorating covers.
    def self.popular_ids(viewer: nil, filter: nil)
      HubScope.relation(viewer:, filter:).most_viewed.limit(POPULAR_LIMIT).pluck(:id)
    end

    def self.decorate(shelves, include_covers: true, include_genres: true)
      new(shelves: Array(shelves), include_covers:, include_genres:).decorate
    end

    def self.recent_scope(exclude_ids: [], viewer: nil, filter: nil)
      scope = HubScope.relation(viewer:, filter:)
                      .includes(user: { avatar: { image_attachment: :blob } })
                      .order(updated_at: :desc)
      ids = Array(exclude_ids).compact
      ids.any? ? scope.where.not(id: ids) : scope
    end

    def initialize(shelves: [], include_covers: true, include_genres: true, viewer: nil, filter: nil)
      @shelves = shelves
      @include_covers = include_covers
      @include_genres = include_genres
      @viewer = viewer
      @filter = filter
    end

    def popular
      shelves = HubScope.relation(viewer: @viewer, filter: @filter)
                        .most_viewed.includes(:user).limit(POPULAR_LIMIT).to_a
      decorate_shelves(shelves, include_covers: true, include_genres: true)
    end

    def decorate
      decorate_shelves(@shelves, include_covers: @include_covers, include_genres: @include_genres)
    end

    private

    def decorate_shelves(shelves, include_covers:, include_genres:)
      @shelves = shelves
      @include_covers = include_covers
      @include_genres = include_genres
      shelves.map { |bookshelf| entry_for(bookshelf) }
    end

    def entry_for(bookshelf)
      Entry.new(
        bookshelf:,
        covers: covers_for(bookshelf),
        fictions_count: fictions_counts.fetch(bookshelf.id, 0),
        top_genres: top_genres_for(bookshelf),
        max_content_rating: max_content_ratings.fetch(bookshelf.id, 0)
      )
    end

    def covers_for(bookshelf)
      return [] unless @include_covers

      cover_fictions.fetch(bookshelf.id, [])
    end

    def top_genres_for(bookshelf)
      return [] unless @include_genres

      top_genre_ids.fetch(bookshelf.id, []).filter_map { |id| genres_by_id[id] }
    end

    def cover_fictions
      @cover_fictions ||= @include_covers ? HubCoverLoader.call(@shelves.map(&:id)) : {}
    end

    def fictions_counts
      @fictions_counts ||= load_grouped_counts
    end

    def max_content_ratings
      @max_content_ratings ||= load_max_content_ratings
    end

    def top_genre_ids
      @top_genre_ids ||= @include_genres ? HubGenreLoader.call(@shelves.map(&:id)) : {}
    end

    def genres_by_id
      @genres_by_id ||= Genre.where(id: top_genre_ids.values.flatten).index_by(&:id)
    end

    def load_grouped_counts
      ids = @shelves.map(&:id)
      return {} if ids.empty?

      BookshelfFiction.where(bookshelf_id: ids).group(:bookshelf_id).count
    end

    def load_max_content_ratings
      ids = @shelves.map(&:id)
      return {} if ids.empty?

      BookshelfFiction.joins(:fiction)
                      .where(bookshelf_id: ids)
                      .group(:bookshelf_id)
                      .maximum('fictions.content_rating')
    end
  end
end
