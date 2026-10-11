# frozen_string_literal: true

module Chapters
  # View helpers for chapter list accordion sections.
  module ListSectionsHelper
    def chapter_list_section_index(fiction, order:, viewer: current_user, read_filter: nil)
      listed = Library::ChapterCatalog.listed_chapters(fiction, viewer:)
      sections = ListSectionIndex.new(listed, order:).call
      read_filter ? read_filter.sections(sections, listed) : sections
    end

    # A licensed work lists only its preview, so the group says so: «Том 1 · Ознайомчий фрагмент · Розділи 1–6».
    # Phones drop the label to keep the range in view; the list header above already names the preview.
    def chapter_list_section_title(fiction, section)
      return section[:title] unless fiction.license_chapters_state == :partial

      *head, range = section[:title].split(' · ')
      label = tag.span("#{t('fictions.chapters_tab.license_preview.group')} · ", class: 'max-md:hidden')
      safe_join([*head.map { |part| "#{part} · " }, label, range])
    end

    # The hidden range follows the last preview chapter, so its row closes that chapter's group.
    def license_hidden_row_section_key(fiction, sections)
      return unless fiction.license_chapters_state == :partial

      last_id = fiction.license_preview.chapter_ids.last
      sections.find { |section| chapter_list_section_ids(section).include?(last_id) }&.fetch(:section_key)
    end

    def license_preview_list_title(fiction)
      preview = fiction.license_preview
      key = preview.available_count == 1 ? :title_one : :title
      t(key, scope: 'fictions.chapters_tab.license_preview', range: preview.available_range)
    end

    def chapter_jump_placeholder(fiction, license_partial)
      return t('fictions.chapters_tab.jump.placeholder') unless license_partial

      t('fictions.chapters_tab.jump.placeholder_range', range: fiction.license_preview.available_range)
    end

    def fiction_chapter_section_path(fiction, section_key, order:, filter: nil)
      chapter_section_fiction_path(fiction, section: section_key, order:, filter:)
    end

    # Only the fiction page list shows scanlator names; the reader drawer does not.
    def fiction_section_chapters(fiction, section, order:, viewer: current_user, scanlators: true)
      ids = chapter_list_section_ids(section)
      Library::ChapterCatalog.listed_section_chapters(fiction, ids, viewer:, order:, scanlators:)
    end

    # The fiction page opens a group on its first page; «Показати ще» fetches the rest. When the group holds the
    # continue chapter (`through`), the page grows in phone-sized steps until that row is on it.
    def fiction_section_first_page(fiction, section, order:, viewer: current_user, through: nil)
      chapters = fiction_section_chapters(fiction, section, order:, viewer:, scanlators: false)
      chapters = chapters.first(chapter_list_first_page_size(chapters.index { |chapter| chapter.id == through&.id }))
      ActiveRecord::Associations::Preloader.new(records: chapters, associations: :scanlators).call
      chapters
    end

    def chapter_list_first_page_size(focus_index)
      page_size = Fictions::ChapterSectionLoader::PAGE_SIZE
      return page_size unless focus_index

      step = Fictions::ChapterSectionLoader::MOBILE_PAGE_SIZE
      [page_size, ((focus_index / step) + 1) * step].max
    end

    # «1622–1700», or «1700» for one chapter.
    def chapter_number_range(chapters)
      first, last = chapters.map(&:number).minmax.map { |number| Formatting.format_decimal(number).to_s }
      first == last ? first : "#{first}–#{last}"
    end

    # The group holding the continue chapter, or the first group in the current sort.
    def chapter_list_open_section_key(sections, continue_chapter)
      keys = sections.pluck(:section_key)
      key = ListSectionIndex.section_key_for(continue_chapter) if continue_chapter
      keys.include?(key) ? key : keys.first
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
