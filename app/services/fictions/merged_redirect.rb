# frozen_string_literal: true

module Fictions
  # Resolves a slug that belongs to a merged fiction to the live fiction at the end of the chain.
  # friendly_id has no history, so this lookup is the only old-URL redirect.
  class MergedRedirect
    MAX_HOPS = 5

    def initialize(slug)
      @slug = slug.to_s
    end

    def target
      follow(merged_source)
    end

    private

    attr_reader :slug

    def merged_source
      Fiction.with_deleted.where.not(merged_into_id: nil).find_by(slug:)
    end

    def follow(current)
      MAX_HOPS.times do
        nxt = next_fiction(current)
        return nxt if nxt.nil? || !nxt.deleted?

        current = nxt
      end
      nil
    end

    def next_fiction(current)
      return if current&.merged_into_id.nil?

      Fiction.with_deleted.find_by(id: current.merged_into_id)
    end
  end
end
