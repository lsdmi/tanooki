# frozen_string_literal: true

class TrendingTagsService
  def self.call
    new.call
  end

  def call
    Rails.cache.fetch('trending_tags', expires_in: 1.hour) do
      Tag.where(name: trending_tag_names).order(:name)
    end
  end

  private

  def trending_tag_names
    limited(
      Tag.joins(:publications)
         .select(:name)
         .where(publications: { created_at: 14.days.ago.. })
         .group('tags.id')
         .order('SUM(publications.views) DESC')
         .limit(5)
         .pluck(:name)
    )
  end

  def limited(names)
    return names.take(3) if names.take(4).join.size > 45
    return names.take(4) if names.take(5).join.size > 45

    names
  end
end
