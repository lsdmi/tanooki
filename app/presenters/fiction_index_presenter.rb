# frozen_string_literal: true

# View-model for the fictions index carousels and sections.
class FictionIndexPresenter
  def popular_novelty
    @popular_novelty ||= Fictions::IndexVariablesManager.popular_novelty
  end

  def popular_novelty_featured
    return @popular_novelty_featured if defined?(@popular_novelty_featured)

    @popular_novelty_featured = Array(popular_novelty).first
    return unless @popular_novelty_featured

    ActiveRecord::Associations::Preloader.new(
      records: [@popular_novelty_featured],
      associations: %i[genres fiction_ratings]
    ).call
    @popular_novelty_featured
  end

  def popular_novelty_featured_chapter_count
    return 0 unless popular_novelty_featured

    Chapter.released.where(fiction_id: popular_novelty_featured.id).count
  end

  def most_reads
    @most_reads ||= Fictions::IndexVariablesManager.most_reads
  end

  def originals
    @originals ||= Fictions::IndexVariablesManager.originals
  end

  def fanfictions
    @fanfictions ||= Fictions::IndexVariablesManager.fanfictions
  end

  def genre_spotlight
    @genre_spotlight ||= Fictions::IndexVariablesManager.genre_spotlight
  end

  def latest_updates
    @latest_updates ||= Fictions::IndexVariablesManager.latest_updates
  end

  def latest_update_chapters
    @latest_update_chapters ||= Fictions::LatestReleasedChapters.for_fiction_ids(latest_updates.map(&:id))
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

  def showcase
    @showcase ||= Fictions::IndexVariablesManager.showcase
  end
end
