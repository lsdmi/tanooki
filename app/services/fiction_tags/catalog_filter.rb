# frozen_string_literal: true

module FictionTags
  # Narrows a fiction scope to works that carry every requested tag (AND).
  # An unknown or not visible slug matches nothing, so a shared link to a removed tag gives an empty list.
  class CatalogFilter
    def self.apply(scope, slugs, explicit:)
      slugs = Array(slugs).map(&:to_s).uniq
      return scope if slugs.empty?

      tag_ids = CatalogFacet.visible(explicit:).where(slug: slugs).pluck(:id)
      return scope.none if tag_ids.size < slugs.size

      matching = FictionTagLink.where(fiction_tag_id: tag_ids)
                               .group(:fiction_id)
                               .having('COUNT(*) = ?', tag_ids.size)
                               .select(:fiction_id)
      scope.where(id: matching)
    end
  end
end
