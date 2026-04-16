# frozen_string_literal: true

class FictionIndexPresenter
  def initialize(params)
    @params = params
  end

  def hero_ad
    @hero_ad ||= Advertisement.find_by(slug: 'fictions-index-hero-ad')
  end

  def popular_novelty
    @popular_novelty ||= FictionIndexVariablesManager.popular_novelty
  end

  def most_reads
    @most_reads ||= FictionIndexVariablesManager.most_reads
  end

  def latest_updates
    @latest_updates ||= FictionIndexVariablesManager.latest_updates
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
    @showcase ||= FictionIndexVariablesManager.showcase
  end

  def filtered_fictions_locals
    {
      fictions: other,
      genres:,
      sample_genre:
    }
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
    subquery_sql = latest_released_chapters_subquery_sql
    Fiction.joins(:genres)
           .joins("INNER JOIN (#{subquery_sql}) AS latest_chapters ON latest_chapters.fiction_id = fictions.id")
           .includes(:cover_attachment)
  end

  def latest_released_chapters_subquery_sql
    Chapter.released
           .select('fiction_id, MAX(created_at) AS max_created_at')
           .group(:fiction_id)
           .to_sql
  end
end
