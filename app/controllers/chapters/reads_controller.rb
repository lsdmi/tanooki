# frozen_string_literal: true

module Chapters
  # Manual read / unread toggle from the reader drawer. Responds with the re-rendered drawer row.
  class ReadsController < ApplicationController
    helper Chapters::ChapterDrawerHelper

    before_action :authenticate_user!
    before_action :set_chapter

    def create
      Reading::RecordCompletion.new(chapter: @chapter, user: current_user, source: 'manual').call
      render_drawer_row
    end

    def destroy
      Reading::RemoveRead.new(chapter: @chapter, user: current_user).call
      render_drawer_row
    end

    private

    # Only chapters the drawer can list for this viewer: no drafts, no scheduled chapters of other teams.
    def set_chapter
      chapter = Chapter.friendly.find(params.expect(:chapter_id))
      listable = Library::ChapterCatalog.chapters_scope_for_list(chapter.fiction, current_user).exists?(chapter.id)
      listable ? @chapter = chapter : head(:not_found)
    end

    def render_drawer_row
      respond_to do |format|
        format.turbo_stream { render turbo_stream: drawer_row_streams }
        format.html { redirect_back_or_to chapter_path(@chapter) }
      end
    end

    # The drawer lists every translation as its own row, and a read ticks all of them.
    def drawer_row_streams
      locals = drawer_row_locals
      listed_translations.map do |chapter|
        turbo_stream.replace(helpers.dom_id(chapter, :reader_drawer),
                             partial: 'fictions/chapter_item', locals: locals.merge(chapter:))
      end
    end

    def listed_translations
      Library::ChapterCatalog.chapters_scope_for_list(@chapter.fiction, current_user)
                             .where(volume_number: @chapter.volume_number, number: @chapter.number)
    end

    def drawer_row_locals
      current_chapter = Chapter.find_by(id: params[:current_chapter_id])
      drawer_progress = Reading::ChapterDrawerProgress.build(
        fiction: @chapter.fiction, viewer: current_user, current_chapter:
      )
      { reader_drawer: true, current_chapter:, drawer_progress: }
    end
  end
end
