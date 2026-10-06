# frozen_string_literal: true

module Chapters
  # Manual read / unread toggle from the reader drawer or the fiction page list (`fiction_list`).
  # Responds with the re-rendered rows of the list the toggle came from; the fiction list also gets its counters.
  class ReadsController < ApplicationController
    include FictionListReadStreams

    helper Chapters::ChapterDrawerHelper, Ui::StrokeIconHelper

    before_action :authenticate_user!
    before_action :set_chapter
    before_action :remember_continue_target, if: :fiction_list?

    def create
      Reading::RecordCompletion.new(chapter: @chapter, user: current_user, source: 'manual').call
      render_rows
    end

    def destroy
      Reading::RemoveRead.new(chapter: @chapter, user: current_user).call
      render_rows
    end

    private

    def set_chapter
      @chapter = Chapter.friendly.find(params.expect(:chapter_id))
      head(:not_found) unless list_scope.exists?(@chapter.id)
    end

    def render_rows
      respond_to do |format|
        format.turbo_stream { render turbo_stream: row_streams }
        format.html { redirect_back_or_to chapter_path(@chapter) }
      end
    end

    # Both lists show every translation as its own row, and a read ticks all of them.
    def row_streams
      return fiction_list_streams(listed_translations.to_a) if fiction_list?

      locals = drawer_row_locals
      listed_translations.map { |chapter| row_stream(chapter, :reader_drawer, locals) }
    end

    def row_stream(chapter, prefix, locals)
      turbo_stream.replace(helpers.dom_id(chapter, prefix), partial: 'fictions/chapter_item',
                                                            locals: locals.merge(chapter:))
    end

    def fiction_list? = params[:fiction_list].present?

    def fiction = @chapter.fiction

    def listed_translations
      list_scope.where(volume_number: @chapter.volume_number, number: @chapter.number)
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
