# frozen_string_literal: true

class FictionListsController < ApplicationController
  before_action :load_advertisement

  def alphabetical
    @pagy, @fictions = pagy(filtered_fictions, limit: 8)

    respond_to do |format|
      format.html
      format.turbo_stream { render_fictions_list }
    end
  end

  private

  def render_fictions_list
    render turbo_stream: turbo_stream.update(
      'fiction-list-page',
      partial: 'dynamic_content',
      locals: { fictions: @fictions, pagy: @pagy }
    )
  end

  def filtered_fictions
    Fiction.from(fiction_subquery, :fictions)
           .includes(:cover_attachment, :genres, :scanlators)
           .order(Arel.sql('COALESCE(max_created_at, fictions.created_at) DESC'))
  end

  def fiction_subquery
    Fiction.where(id: cached_fiction_ids)
           .left_joins(:chapters)
           .select('fictions.*, MAX(chapters.created_at) AS max_created_at')
           .group('fictions.id, fictions.created_at')
  end

  def cached_fiction_ids
    Rails.cache.fetch(fiction_ids_cache_key, expires_in: 1.day) do
      fiction_ids_query.pluck(:id)
    end
  end

  def fiction_ids_cache_key
    if genre_id.present?
      "fictions_genre_#{genre_id}_ids"
    else
      'default_fictions_alphabetical_ids'
    end
  end

  def fiction_ids_query
    scope = Fiction.left_joins(:chapters)
                   .select('fictions.id')
                   .group('fictions.id, fictions.created_at')
                   .order(Arel.sql('COALESCE(MAX(chapters.created_at), fictions.created_at) DESC'))

    genre_id.present? ? scope.joins(:genres).where(genres: { id: genre_id }) : scope
  end

  def genre_id
    params['genre-radio'].presence
  end
end
