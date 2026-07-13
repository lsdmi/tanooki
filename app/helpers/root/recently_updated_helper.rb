# frozen_string_literal: true

module Root
  # Card copy for the home page «Нові Релізи» grid.
  module RecentlyUpdatedHelper
    include Chapters::FormHelper

    def recently_updated_cards(fictions, latest_chapters_by_fiction)
      fictions.filter_map do |fiction|
        chapter = latest_chapters_by_fiction[fiction.id]
        next unless chapter

        { fiction: fiction, chapter: chapter }
      end
    end

    def recently_updated_chapter_label(chapter)
      "Розділ #{format_decimal(chapter.number)}"
    end

    def recently_updated_timestamp(chapter)
      "#{time_ago_in_words(chapter.public_at, locale: :uk)} тому"
    end
  end
end
