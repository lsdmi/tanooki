# frozen_string_literal: true

module Fictions
  # Latest released chapter per fiction for update cards.
  class LatestReleasedChapters
    def self.for_fiction_ids(fiction_ids)
      new(fiction_ids).call
    end

    def initialize(fiction_ids)
      @fiction_ids = Array(fiction_ids).compact
    end

    def call
      return {} if @fiction_ids.blank?

      ranked = Chapter.released
                      .where(fiction_id: @fiction_ids)
                      .select("fiction_id, MAX(#{Chapter::PUBLIC_TIME_SQL}) AS max_public_at")
                      .group(:fiction_id)

      Chapter.released
             .joins(join_latest_sql(ranked))
             .where(fiction_id: @fiction_ids)
             .each_with_object({}) { |chapter, result| result[chapter.fiction_id] ||= chapter }
    end

    private

    def join_latest_sql(ranked)
      <<~SQL.squish
        INNER JOIN (#{ranked.to_sql}) AS latest
          ON latest.fiction_id = chapters.fiction_id
         AND #{Chapter::PUBLIC_TIME_SQL} = latest.max_public_at
      SQL
    end
  end
end
