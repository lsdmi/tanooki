# frozen_string_literal: true

# Blog-style publications (tales): list, show, and tag browsing.
class TalesController < ApplicationController
  HIGHLIGHTS_LIMIT = Publications::PublicCache::HIGHLIGHTS_LIMIT
  PUBLICATIONS_PER_PAGE = 16
  OPENSEARCH_CONNECTION_ERRORS = [
    Faraday::Error,
    Errno::ECONNREFUSED,
    SocketError,
    Timeout::Error,
    OpenSearch::Transport::Transport::Error
  ].freeze
  helper Publications::CoverHeaderHelper
  include PublicationPublicAccess

  before_action :set_tale, only: :show
  before_action :redirect_if_publication_not_public, only: :show
  before_action :track_visit, only: :show
  before_action :pokemon_appearance, only: %i[index show]

  def index
    @highlights = highlights
    @pagy, @publications = pagy_countless(publications, limit: PUBLICATIONS_PER_PAGE)
    @publication_tag_counts = search_tag_counts(publication_search_tags)
    @tile_offset = @highlights.size + ((@pagy.page - 1) * PUBLICATIONS_PER_PAGE)

    render 'home/scrollable_list' if params[:page]
  end

  def show
    @more_tales = more_tails
    @comments = @publication.comments.parents
                            .includes(
                              user: { avatar: :image_attachment },
                              replies: { user: { avatar: :image_attachment } }
                            )
                            .order(created_at: :desc)
    @comment = Comment.new
    @publication_tag_counts = search_tag_counts(Search::TagCounts.labels_from_publications(@publication))
  end

  private

  def more_tails
    related = if base_search.size > 5
                base_search.excluding(@publication).first(5)
              else
                (
                  base_search.to_a + catalog_publications.first(6)
                ).excluding(@publication).uniq.first(5)
              end
    Array(related).select(&:published?)
  end

  def base_search
    @base_search ||= Publication.search(
      @publication.tags.pluck(:name).join(' '),
      fields: ['tags^10', 'title^5', 'description'],
      boost_by_recency: { created_at: { scale: '7d', decay: 0.9 } },
      operator: 'or'
    ).includes([{ cover_attachment: :blob }, :rich_text_description])
  rescue *OPENSEARCH_CONNECTION_ERRORS => e
    Rails.logger.warn("[tales] OpenSearch unavailable for more_tails: #{e.class}: #{e.message}")
    Publication.none
  end

  def set_tale
    @publication = @commentable = load_publication_for_show
  end

  def all_publications
    catalog_publications.includes(:tags)
  end

  def catalog_publications
    Publication.published.includes([{ cover_attachment: :blob }, :rich_text_description]).order(created_at: :desc)
  end

  def highlights
    Publication.published.includes(%i[cover_attachment rich_text_description
                                      tags]).where(id: highlight_ids).order(created_at: :desc)
  end

  def publications
    cached_ids = Rails.cache.fetch(Publications::PublicCache::EXCLUDING_HIGHLIGHTS_KEY,
                                   expires_in: Publications::PublicCache::LIST_TTL) do
      all_publications.where.not(id: highlight_ids).map(&:id)
    end
    Publication.published.includes(%i[cover_attachment rich_text_description
                                      tags]).where(id: cached_ids).order(created_at: :desc)
  end

  def highlight_ids
    Rails.cache.fetch(Publications::PublicCache::HIGHLIGHTS_KEY, expires_in: Publications::PublicCache::LIST_TTL) do
      all_publications.first(HIGHLIGHTS_LIMIT).map(&:id)
    end
  end

  def publication_search_tags
    (
      Search::TagCounts.labels_from_publications(@publications) +
        Search::TagCounts.labels_from_publications(@highlights)
    ).uniq
  end
end
