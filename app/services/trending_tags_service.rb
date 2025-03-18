# frozen_string_literal: true

class TrendingTagsService
  include Rails.application.routes.url_helpers

  def footer
    Rails.cache.fetch('trending_tags_footer', expires_in: 12.hours) do
      tags = Tag.where(name: trending_tag_names)

      tag_data = tags.map do |tag|
        { name: tag.name, link: search_index_path(search: [tag.name]) }
      end

      tag_data.sort_by { |tag| tag[:name] }
    end
  end

  def navbar
    Rails.cache.fetch('trending_tags_navbar', expires_in: 12.hours) do
      build_tag_hash(Tag.where(name: limited(trending_tag_names)).order(:name))
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
      { name: 'Ранобе', link: fictions_path },
      { name: 'Сховище', link: alphabetical_fictions_path }
    ]
  end

  def trending_tag_names
    Tag.joins(:publications)
       .select(:name)
       .where(publications: { created_at: 21.days.ago.. })
       .group('tags.id')
       .order('SUM(publications.views) DESC')
       .limit(16)
       .pluck(:name)
  end

  def limited(names)
    return names.take(1) if names.take(2).join.size > 110

    names.take(2)
  end
end
