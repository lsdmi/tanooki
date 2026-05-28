# frozen_string_literal: true

# View-model for the fictions index: hero ad, carousels, and list filter state.
class FictionIndexPresenter
  def initialize(params)
    @params = params
  end

  def hero_ad
    return @hero_ad if defined?(@hero_ad)

    @hero_ad = Advertisement.find_by(slug: 'fictions-index-hero-ad')
  end

  def popular_novelty
    @popular_novelty ||= Fictions::IndexVariablesManager.popular_novelty
  end

  def most_reads
    @most_reads ||= Fictions::IndexVariablesManager.most_reads
  end

  def released_chapters_counts_for_most_reads
    @released_chapters_counts_for_most_reads ||= begin
      fiction_ids = Array(most_reads).map(&:id)
      Rails.cache.fetch(['fiction_index/released_chapters_by_fiction', fiction_ids.sort], expires_in: 12.hours) do
        Chapter.released
               .where(fiction_id: fiction_ids)
               .group(:fiction_id)
               .count
      end
    end
  end

  def latest_updates
    @latest_updates ||= Fictions::IndexVariablesManager.latest_updates
  end

  def carousel_popular_novelty_ids
    @carousel_popular_novelty_ids ||= Fictions::IndexVariablesManager.popular_novelty_ids_for_badges
  end

  def carousel_most_read_ids
    @carousel_most_read_ids ||= Fictions::IndexVariablesManager.most_reads_ids_for_badges
  end

  def carousel_latest_update_ids
    @carousel_latest_update_ids ||= Fictions::IndexVariablesManager.latest_updates_ids_for_badges
  end

  def genres
    @genres ||= Genre.order(:name).distinct
  end

  def sample_genre
    @sample_genre ||= genres.find_by(id: @params[:genre_id]) || genres.sample
  end

  def other
    @other ||= filtered_fiction_with_max_created_at_query
  end

  def showcase
    @showcase ||= Fictions::IndexVariablesManager.showcase
  end

  private

  def filtered_fiction_with_max_created_at_query
    fictions_joined_to_latest_released_chapter
      .where(genres: { id: sample_genre })
      .select('fictions.*, latest_chapters.max_created_at')
      .order('latest_chapters.max_created_at DESC')
      .limit(8)
  end

  def fictions_joined_to_latest_released_chapter
    Fiction.joins(:genres)
           .joins(
             "INNER JOIN (#{Chapter.released
               .select('fiction_id, MAX(COALESCE(published_at, created_at)) AS max_created_at')
               .group(:fiction_id)
               .to_sql}) AS latest_chapters ON latest_chapters.fiction_id = fictions.id"
           )
           .includes(:cover_attachment)
  end
end
