# frozen_string_literal: true

module FictionTags
  # Which tags the catalog can filter by. One rule for the drawer, the selected chips and the query:
  # only active tags, and 18+ tags only when the reader has 18+ on (`explicit:`).
  class CatalogFacet
    # The drawer lists this many tags first; the rest show up when the reader searches.
    FEATURED = 12

    class << self
      def visible(explicit:)
        explicit ? FictionTag.active : FictionTag.active.where(explicit: false)
      end

      # Tags with at least one work, most used first. Hidden or empty tags never reach the drawer.
      def options(explicit:)
        visible(explicit:).where('fictions_count > 0').order(fictions_count: :desc, name: :asc).to_a
      end

      # Tags for the requested slugs, in the order they were asked for. Unknown or not visible slugs are skipped.
      def selected(slugs, explicit:)
        return [] if slugs.blank?

        by_slug = visible(explicit:).where(slug: slugs).index_by(&:slug)
        slugs.filter_map { |slug| by_slug[slug] }
      end
    end
  end
end
