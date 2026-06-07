# frozen_string_literal: true

module Fictions
  # Builds locals for lazy-loaded chapter section partials in the reader drawer.
  module ChapterSectionRendering
    extend ActiveSupport::Concern

    private

    def chapter_from_section_params
      return nil if params[:current_chapter_id].blank?

      Chapter.find_by(id: params[:current_chapter_id])
    end

    def chapter_section_locals(_order)
      reader_drawer = ActiveModel::Type::Boolean.new.cast(params[:reader_drawer])
      current_chapter = chapter_from_section_params
      locals = { chapters: @section_chapters, reader_drawer:, current_chapter: }
      return locals unless reader_drawer

      locals.merge(drawer_progress: chapter_section_drawer_progress(current_chapter))
    end

    def chapter_section_drawer_progress(current_chapter)
      Reading::ChapterDrawerProgress.build(
        fiction: @fiction,
        viewer: current_user,
        current_chapter:
      )
    end

    def load_chapter_section(order)
      Fictions::ChapterSectionLoader.new(
        fiction: @fiction,
        viewer: current_user,
        section_key: params[:section],
        order: order,
        chapter_ids: params[:chapter_ids]
      ).call
    end

    def render_chapter_section_items(order)
      render partial: 'fictions/chapter_section_items', layout: false, locals: chapter_section_locals(order)
    end
  end
end
