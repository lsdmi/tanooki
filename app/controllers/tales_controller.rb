# frozen_string_literal: true

class TalesController < ApplicationController
  before_action :load_advertisement, only: %i[index show]
  before_action :set_tale, :track_visit, only: :show
  before_action :pokemon_appearance, only: %i[index show]

  def index
    @highlights = highlights
    @pagy, @publications = pagy_countless(publications, limit: 17)

    render 'home/scrollable_list' if params[:page]
  end

  def show
    @more_tales = more_tails
    @comments = @publication.comments.parents.includes(user: { avatar: :image_attachment },
                                                       replies: { user: { avatar: :image_attachment } }).order(created_at: :desc)
    @comment = Comment.new
  end

  private

  def more_tails
    return base_search.excluding(@publication).first(5) if base_search.size > 5

    (
      base_search.to_a + Publication.all.includes([{ cover_attachment: :blob },
                                                   :rich_text_description]).order(created_at: :desc).first(6)
    ).excluding(@publication).uniq.first(5)
  end

  def base_search
    return [] unless Searchkick.client.ping

    @base_search ||= Publication.search(
      @publication.tags.pluck(:name).join(' '),
      fields: ['tags^10', 'title^5', 'description'],
      boost_by_recency: { created_at: { scale: '7d', decay: 0.9 } },
      operator: 'or'
    ).includes([{ cover_attachment: :blob }, :rich_text_description])
  end

  def set_tale
    @publication = @commentable = Rails.cache.fetch("publication_#{params[:id]}", expires_in: 1.hour) do
      Publication.find(params[:id])
    end
  end

  def all_publications
    Publication.includes([{ cover_attachment: :blob }, :rich_text_description, :tags]).order(created_at: :desc)
  end

  def highlights
    cached_ids = highlight_ids
    Publication.includes(%i[cover_attachment rich_text_description
                            tags]).where(id: cached_ids).order(created_at: :desc)
  end

  def publications
    cached_ids = Rails.cache.fetch('publications', expires_in: 4.hours) do
      all_publications.where.not(id: highlight_ids).map(&:id)
    end
    Publication.includes(%i[cover_attachment rich_text_description
                            tags]).where(id: cached_ids).order(created_at: :desc)
  end

  def highlight_ids
    Rails.cache.fetch('highlights', expires_in: 4.hours) do
      all_publications.first(11).map(&:id)
    end
  end
end
