# frozen_string_literal: true

module Scanlators
  # Cached stats for the scanlator team profile page.
  class ShowPresenter
    CACHE_EXPIRY = 1.hour

    delegate :chapters_count, :total_views, :active_recently?, :average_rating, :total_rating_count,
             to: :stats

    def initialize(scanlator)
      @scanlator = scanlator
    end

    def self.cache_key_for(scanlator_id)
      "scanlator:#{scanlator_id}:stats"
    end

    def self.invalidate(scanlator_id)
      Rails.cache.delete(cache_key_for(scanlator_id))
    end

    def self.invalidate_for_scanlators(scanlator_ids)
      Array(scanlator_ids).compact.uniq.each { |id| invalidate(id) }
    end

    private

    def stats
      @stats ||= load_stats
    end

    def load_stats
      cached = Rails.cache.fetch(self.class.cache_key_for(@scanlator.id), expires_in: CACHE_EXPIRY) do
        Stats.compute(@scanlator).to_h
      end

      Stats.from_h(cached)
    end
  end
end
