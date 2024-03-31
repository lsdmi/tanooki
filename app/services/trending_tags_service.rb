# frozen_string_literal: true

class TrendingTagsService
  include Rails.application.routes.url_helpers

  def self.call
    new.call
  end

  def call
    Rails.cache.fetch('trending_tags', expires_in: 1.hour) do
      build_tag_hash(Tag.where(name: trending_tag_names).order(:name))
    end
  end

  private

  def build_tag_hash(tags)
    all_tags = tags.map { |tag| { name: tag.name, link: search_index_path(search: [tag.name]) } }
    (all_tags + hardcoded_tags).sort_by { |tag| tag[:name] }
  end

  def hardcoded_tags
    [
      { name: 'Блоги', link: tales_path },
      { name: 'Відео', link: youtube_videos_path },
      { name: 'Обговорення', link: comments_path },
      { name: 'Ранобе', link: fictions_path }
    ]
  end

  def trending_tag_names
    limited(
      Tag.joins(:publications)
         .select(:name)
         .where(publications: { created_at: 14.days.ago.. })
         .group('tags.id')
         .order('SUM(publications.views) DESC')
         .limit(3)
         .pluck(:name)
    )
  end

  def limited(names)
    return names.take(1) if names.take(2).join.size > 110
    return names.take(2) if names.take(3).join.size > 110

    names
  end
end
