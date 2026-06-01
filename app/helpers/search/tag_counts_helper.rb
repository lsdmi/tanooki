# frozen_string_literal: true

module Search
  # View/controller helper for cached OpenSearch result counts on tag labels.
  module TagCountsHelper
    def search_tag_counts(labels, scope: :all)
      TagCounts.call(labels, scope: scope)
    end
  end
end
