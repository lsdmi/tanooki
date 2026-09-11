# frozen_string_literal: true

module Catalog
  # Maps fictions to the current listing nudge for studio dashboards.
  class ListingNudgeFlags
    Flag = Data.define(:kind, :body)

    def self.for_fictions(fictions)
      Array(fictions).each_with_object({}) do |fiction, flags|
        flag = flag_for(fiction)
        flags[fiction.id] = flag if flag
      end
    end

    def self.flag_for(fiction)
      nudge = ListingNudge.for(fiction)
      return unless nudge

      Flag.new(
        kind: nudge.kind,
        body: I18n.t(
          "fictions.listing_nudges.#{nudge.kind}.body",
          count: nudge.chapter_count,
          plan: nudge.expected_chapters
        )
      )
    end
    private_class_method :flag_for
  end
end
