# frozen_string_literal: true

module Chapters
  # Manual read / unread toggle from the reader drawer or the fiction page list (`fiction_list`).
  # Responds with the re-rendered rows of the list the toggle came from.
  class ReadsController < ApplicationController
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

    # Only chapters the drawer can list for this viewer: no drafts, no scheduled chapters of other teams.
    def set_chapter
      chapter = Chapter.friendly.find(params.expect(:chapter_id))
      listable = Library::ChapterCatalog.chapters_scope_for_list(chapter.fiction, current_user).exists?(chapter.id)
      listable ? @chapter = chapter : head(:not_found)
    end

    def render_rows
      respond_to do |format|
        format.turbo_stream { render turbo_stream: row_streams }
        format.html { redirect_back_or_to chapter_path(@chapter) }
      end
    end

    def fiction_list? = params[:fiction_list].present?

    def remember_continue_target
      @continue_before = list_progress.continue_chapter_id
    end

    # Both lists show every translation as its own row, and a read ticks all of them.
    def row_streams
      return fiction_list_streams if fiction_list?

      locals = drawer_row_locals
      listed_translations.map { |chapter| row_stream(chapter, :reader_drawer, locals) }
    end

    # A toggle that moves the continue target also re-renders the old and new continue rows and the chip.
    def fiction_list_streams
      progress = list_progress
      continue_id = progress.continue_chapter_id
      return list_row_streams(listed_translations, progress) if continue_id == @continue_before

      chapters = with_continue_rows(continue_id)
      continue_chapter = chapters.find { |chapter| chapter.id == continue_id }
      list_row_streams(chapters, progress) << continue_chip_stream(continue_chapter)
    end

    def with_continue_rows(continue_id)
      translations = listed_translations.to_a
      translations + listable.where(id: [@continue_before, continue_id].compact).where.not(id: translations.map(&:id))
    end

    def list_row_streams(chapters, progress)
      chapters.map { |chapter| row_stream(chapter, :chapter_list, reader_drawer: false, drawer_progress: progress) }
    end

    def continue_chip_stream(continue_chapter)
      turbo_stream.update('chapter_continue_chip', partial: 'fictions/continue_chip', locals: { continue_chapter: })
    end

    def row_stream(chapter, prefix, locals)
      turbo_stream.replace(helpers.dom_id(chapter, prefix), partial: 'fictions/chapter_item',
                                                            locals: locals.merge(chapter:))
    end

    def listable
      Library::ChapterCatalog.chapters_scope_for_list(@chapter.fiction, current_user)
    end

    def listed_translations
      listable.where(volume_number: @chapter.volume_number, number: @chapter.number)
    end

    def list_progress
      Reading::ChapterDrawerProgress.build(fiction: @chapter.fiction, viewer: current_user)
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
