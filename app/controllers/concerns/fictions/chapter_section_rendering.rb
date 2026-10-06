# frozen_string_literal: true

module Fictions
  # Builds locals for lazy-loaded chapter section partials in the reader drawer and the fiction page.
  #
  # The fiction page pages through a group: without `offset` the response is the group body (first `limit` rows plus
  # the «Показати ще» footer); with `offset` it is only the next rows to append. `limit=all` loads the rest.
  module ChapterSectionRendering
    extend ActiveSupport::Concern

    MAX_PAGE_SIZE = 100

    private

    def chapter_from_section_params
      return nil if params[:current_chapter_id].blank?

      Chapter.find_by(id: params[:current_chapter_id])
    end

    def chapter_section_reader_drawer?
      ActiveModel::Type::Boolean.new.cast(params[:reader_drawer])
    end

    def chapter_section_limit
      return nil if chapter_section_reader_drawer? || params[:limit] == 'all'

      (params[:limit].presence || Fictions::ChapterSectionLoader::PAGE_SIZE).to_i.clamp(1, MAX_PAGE_SIZE)
    end

    def chapter_section_offset
      chapter_section_reader_drawer? ? 0 : params[:offset].to_i
    end

    def chapter_section_locals(_order)
      reader_drawer = chapter_section_reader_drawer?
      current_chapter = chapter_from_section_params
      locals = { chapters: @section_chapters, reader_drawer:, current_chapter: }
      return locals unless reader_drawer || current_user

      locals.merge(drawer_progress: chapter_section_drawer_progress(current_chapter))
    end

    def chapter_section_drawer_progress(current_chapter)
      Reading::ChapterDrawerProgress.build(
        fiction: @fiction,
        viewer: current_user,
        current_chapter:
      )
    end

    def chapter_section_loader(order)
      @chapter_section_loader ||= Fictions::ChapterSectionLoader.new(
        fiction: @fiction,
        viewer: current_user,
        section_key: params[:section],
        order: order,
        read_filter: chapter_section_read_filter
      )
    end

    def chapter_section_read_filter
      return if chapter_section_reader_drawer? || current_user.nil?

      Chapters::ReadFilter.new(params[:filter], progress: chapter_section_drawer_progress(nil))
    end

    def load_chapter_section(order)
      chapter_section_loader(order).call(offset: chapter_section_offset, limit: chapter_section_limit).to_a
    end

    def render_chapter_section_items(order)
      locals = chapter_section_locals(order)
      return render_chapter_section_rows(locals) if !locals[:reader_drawer] && params.key?(:offset)

      locals.merge!(chapter_section_page_locals(order)) unless locals[:reader_drawer]
      render partial: 'fictions/chapter_section_items', layout: false, locals:
    end

    def render_chapter_section_rows(locals)
      render partial: 'fictions/chapter_section_rows', layout: false, locals:
    end

    def chapter_section_page_locals(order)
      limit = chapter_section_limit
      shown = @section_chapters.size
      total = limit && shown >= limit ? chapter_section_loader(order).total : shown
      filter = chapter_section_read_filter&.value
      { total:, section_url: chapter_section_fiction_path(@fiction, section: params[:section], order:, filter:) }
    end
  end
end
