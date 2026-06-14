# frozen_string_literal: true

module Chapters
  # View helpers for chapter list accordion sections.
  module ListSectionsHelper
    def chapter_list_sections(chapters, order: :asc)
      ListSections.new(chapters, order: order).call
    end

    delegate :volume_section_key, :range_section_key, to: ListSections

    def fiction_chapter_section_path(fiction, section_key, order:)
      chapter_section_fiction_path(fiction, section: section_key, order: order)
    end

    def chapter_list_section_ids(section_chapters)
      section_chapters.pluck(:id)
    end

    def chapter_list_section_current?(section, current_chapter_id)
      return false if current_chapter_id.blank?

      section[:chapters].exists?(id: current_chapter_id)
    end
  end
end
