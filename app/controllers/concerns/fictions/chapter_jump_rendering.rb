# frozen_string_literal: true

module Fictions
  # JSON for «Перейти до розділу» on the fiction page: the group to open and its body rendered as a window of rows
  # around the chapter, or the inline error for the field.
  module ChapterJumpRendering
    extend ActiveSupport::Concern

    private

    def chapter_jump_payload(order)
      listed = Library::ChapterCatalog.listed_chapters(@fiction, viewer: current_user)
      result = chapter_jump_result(listed, order)
      return { error: chapter_jump_error(result, listed) } unless result.found?

      html = render_to_string(partial: 'fictions/chapter_section_items', formats: :html,
                              locals: chapter_jump_locals(result, order))
      { section_key: result.section[:section_key], target_index: result.target_index, html: }
    end

    def chapter_jump_result(listed, order)
      Fictions::ChapterJump.new(
        listed:,
        sections: helpers.chapter_list_section_index(@fiction, order:),
        query: params[:number],
        section_rows: ->(section) { helpers.fiction_section_chapters(@fiction, section, order:, scanlators: false) },
        chapter_id: Integer(params[:chapter_id].to_s, 10, exception: false)
      ).call
    end

    def chapter_jump_error(result, listed)
      return t('fictions.chapters_tab.jump.invalid') if result.error == :invalid
      return t('fictions.chapters_tab.jump.failed') unless result.number

      t('fictions.chapters_tab.jump.missing', number: Chapters::Formatting.format_decimal(result.number),
                                              range: helpers.chapter_number_range(listed))
    end

    def chapter_jump_locals(result, order)
      window = result.window
      ActiveRecord::Associations::Preloader.new(records: window, associations: :scanlators).call
      locals = {
        chapters: window, total: result.rows.size, window_start: result.window_start, mobile_trim: false,
        section_url: helpers.fiction_chapter_section_path(@fiction, result.section[:section_key], order:),
        before_label: chapter_jump_before_label(result)
      }
      current_user ? locals.merge(drawer_progress: helpers.reader_chapter_drawer_progress(@fiction)) : locals
    end

    def chapter_jump_before_label(result)
      helpers.chapter_number_range(result.rows_above) if result.window_start.positive?
    end
  end
end
