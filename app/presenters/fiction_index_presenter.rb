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

  def hot_updates
    @hot_updates ||= FictionIndexVariablesManager.hot_updates
  end

  def genres
    @genres ||= Genre.joins(:fictions).order(:name).distinct
  end

  def sample_genre
    @sample_genre ||= genres.find_by(id: @params[:genre_id]) || genres.sample
  end

  def other
    @other ||= filtered_fiction_with_max_created_at_query
  end

  def filtered_fictions_locals
    {
      other:,
      genres:,
      sample_genre:
    }
  end

  private

  def filtered_fiction_with_max_created_at_query
    Fiction.joins(:chapters).includes([{ cover_attachment: :blob }, :genres, :scanlators])
           .where(genres: { id: sample_genre })
           .select('fictions.*, MAX(chapters.created_at) AS max_created_at')
           .group('fictions.id, active_storage_attachments.id, scanlators.id')
           .order('max_created_at DESC')
  end
end
