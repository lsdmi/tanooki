# frozen_string_literal: true

module Contests
  # Gallery card for an accepted contest entry (no ranking numbers before results).
  class EntryCardComponent < ViewComponent::Base
    include Meta::CoverUrlsHelper

    def initialize(entry:, blur_eighteen: false)
      super()
      @entry = entry
      @fiction = entry.fiction
      @blur_eighteen = blur_eighteen
    end

    def render?
      fiction.present?
    end

    private

    attr_reader :entry, :fiction, :blur_eighteen

    def eighteen?
      fiction.content_rating_eighteen?
    end

    def blur?
      blur_eighteen && eighteen?
    end

    def chapter_count
      fiction.chapter_count.to_i
    end

    def href
      helpers.fiction_path(fiction)
    end
  end
end
