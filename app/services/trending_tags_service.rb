# frozen_string_literal: true

class TrendingTagsService
  include Rails.application.routes.url_helpers

  def tags
    Rails.cache.fetch('trending_tags', expires_in: 12.hours) do
      tags = Tag.where(name: trending_tag_names)

      tag_data = tags.map do |tag|
        { name: tag.name, link: search_index_path(search: [tag.name]) }
      end

      tag_data.sort_by { |tag| tag[:name] }
    end
  end

  private

  def trending_tag_names
    Tag.joins(:publications)
       .select(:name)
       .where(publications: { created_at: 21.days.ago.. })
       .group('tags.id')
       .order('SUM(publications.views) DESC')
       .limit(16)
       .pluck(:name)
  end
end
