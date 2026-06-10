# frozen_string_literal: true

module Search
  # Controller helper for cached OpenSearch result counts on tag labels (via ApplicationController).
  module TagCountsHelper
    def search_tag_counts(labels, scope: :all)
      TagCounts.call(labels, scope: scope)
    end
  end
end
