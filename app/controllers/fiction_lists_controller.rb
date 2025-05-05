# frozen_string_literal: true

class FictionListsController < ApplicationController
  before_action :load_advertisement

  def alphabetical
    @pagy, @fictions = pagy(filtered_list, limit: 8)

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

  def default_list
    Rails.cache.fetch('default_fictions_alphabetical', expires_in: 1.day) do
      Fiction.left_joins(:chapters).joins(:users).includes(:cover_attachment,
                                                           :genres,
                                                           :scanlators)
             .select('fictions.*, MAX(chapters.created_at) AS max_created_at')
             .group('fictions.id, fictions.created_at')
             .order(Arel.sql('COALESCE(MAX(chapters.created_at), fictions.created_at) DESC'))
    end
  end

  def filtered_list
    query = default_list

    query.all
  end
end
