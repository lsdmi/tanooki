# frozen_string_literal: true

class FictionIndexVariablesManager
  def self.popular_fictions
    Rails.cache.fetch('popular_fictions', expires_in: 12.hours) do
      Fiction.includes([{ cover_attachment: :blob }, :genres], :scanlators).order(views: :desc).limit(5)
    end
  end

  def self.most_reads
    Rails.cache.fetch('most_reads', expires_in: 12.hours) do
      Fiction.includes(:scanlators).most_reads.limit(5)
    end
  end

  def self.latest_updates
    Fiction
      .joins(:chapters)
      .includes([{ cover_attachment: :blob }, :genres])
      .select('fictions.*, MAX(chapters.created_at) AS max_created_at')
      .group('fictions.id')
      .order('max_created_at DESC')
      .limit(9)
  end

  def self.hot_updates
    Rails.cache.fetch('hot_updates', expires_in: 12.hours) do
      Fiction
        .joins(:chapters)
        .includes([{ cover_attachment: :blob }, :genres], :scanlators)
        .where('chapters.created_at >= ?', 10.days.ago)
        .select('fictions.*, SUM(chapters.views) AS total_views')
        .group('fictions.id')
        .order('total_views DESC')
        .limit(5)
    end
  end
end
