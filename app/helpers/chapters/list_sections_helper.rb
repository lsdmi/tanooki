# frozen_string_literal: true

module Chapters
  # View helpers for chapter list accordion sections.
  module ListSectionsHelper
    def chapter_list_section_index(fiction, order:, viewer: current_user)
      ListSectionIndex.new(Library::ChapterCatalog.listed_chapters(fiction, viewer:), order:).call
    end

    def fiction_chapter_section_path(fiction, section_key, order:)
      chapter_section_fiction_path(fiction, section: section_key, order: order)
    end

    def fiction_section_chapters(fiction, section_key, order:, viewer: current_user)
      Fictions::ChapterSectionLoader.new(
        fiction: fiction,
        viewer: viewer,
        section_key: section_key,
        order: order
      ).call
    end

    def chapter_list_section_ids(section)
      Array(section[:chapter_ids])
    end

    def chapter_list_section_current?(section, current_chapter_id)
      return false if current_chapter_id.blank?

      chapter_list_section_ids(section).include?(current_chapter_id)
    end

    def epub_download_available_for_section?(fiction, chapter_ids)
      return false unless user_signed_in? && chapter_ids.present?

      ids = chapter_ids.to_set
      listed = Library::ChapterCatalog.listed_chapters_with_scanlators(fiction, viewer: current_user)
      chapters_allow_epub_download?(listed.select { |chapter| ids.include?(chapter.id) })
    end
  end
end
