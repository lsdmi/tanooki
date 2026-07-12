# frozen_string_literal: true

module Fictions
  # Maps fictions to cover quality results for studio dashboards.
  class CoverQualityFlags
    def self.for_fictions(fictions)
      Array(fictions).each_with_object({}) do |fiction, flags|
        result = CoverQuality.call(fiction)
        flags[fiction.id] = result unless result.ok?
      end
    end
  end
end
