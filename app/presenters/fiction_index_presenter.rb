# frozen_string_literal: true

# View-model for the fictions index: hero ad, carousels, and list filter state.
class FictionIndexPresenter
  GENRES_CACHE_EXPIRY = 24.hours
  HERO_AD_CACHE_EXPIRY = 12.hours

  def self.warm_caches!
    Rails.cache.fetch('fiction_index/genres', expires_in: GENRES_CACHE_EXPIRY) do
      Genre.order(:name).distinct.to_a
    end
    Rails.cache.fetch('fiction_index/hero_ad', expires_in: HERO_AD_CACHE_EXPIRY) do
      Advertisement.find_by(slug: 'fictions-index-hero-ad')
    end
  end

  def hero_ad
    @hero_ad ||= Rails.cache.fetch('fiction_index/hero_ad', expires_in: HERO_AD_CACHE_EXPIRY) do
      Advertisement.find_by(slug: 'fictions-index-hero-ad')
    end
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
    @genres ||= Rails.cache.fetch('fiction_index/genres', expires_in: GENRES_CACHE_EXPIRY) do
      Genre.order(:name).distinct.to_a
    end
  end

  def sample_genre
    @sample_genre ||= genres.sample
  end

  def other
    @other ||= Fictions::IndexVariablesManager.filtered_by_genre(sample_genre)
  end

  def showcase
    @showcase ||= Fictions::IndexVariablesManager.showcase
  end
end
