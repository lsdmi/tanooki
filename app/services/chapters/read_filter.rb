# frozen_string_literal: true

module Chapters
  # «Усі · Непрочитані · Прочитані» above the fiction page chapter list. It narrows the rows inside each group;
  # group headers keep their full titles and read counts, and a group with no matching row is left out.
  # In progress counts as unread. Without a reader (guests) it is always «Усі».
  class ReadFilter
    VALUES = %w[unread read].freeze

    attr_reader :value

    def initialize(value, progress:)
      @value = (value.to_s if progress && VALUES.include?(value.to_s))
      @progress = progress
    end

    def active? = !@value.nil?

    def match?(chapter)
      !active? || @progress.read?(chapter) == (@value == 'read')
    end

    # Sections with `chapter_ids` cut to the matching rows; `all_chapter_ids` keeps the whole group (EPUB).
    def sections(sections, listed)
      return sections unless active?

      ids = listed.select { |chapter| match?(chapter) }.to_set(&:id)
      sections.filter_map do |section|
        shown = section[:chapter_ids].select { |id| ids.include?(id) }
        section.merge(chapter_ids: shown, all_chapter_ids: section[:chapter_ids]) if shown.any?
      end
    end

    def listed(listed) = active? ? listed.select { |chapter| match?(chapter) } : listed
  end
end
