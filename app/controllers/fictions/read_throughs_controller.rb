# frozen_string_literal: true

module Fictions
  # «Позначити прочитаними 1–85» from a fiction page row, and its undo. Responds with JSON: the toast message,
  # a signed undo token listing only the reads this call added, and Turbo Streams for the rows the page has
  # loaded (`row_ids`) plus the counters, continue row and hero.
  class ReadThroughsController < ApplicationController
    include Chapters::FictionListReadStreams

    UNDO_TTL = 1.hour
    MAX_ROWS = 2000

    helper Chapters::ChapterDrawerHelper, Ui::StrokeIconHelper

    before_action :authenticate_user!
    before_action :set_fiction
    before_action :remember_continue_target

    def self.verifier
      Rails.application.message_verifier('fictions/read_through')
    end

    def create
      chapter = list_scope.find(params.expect(:chapter_id))
      result = Reading::MarkReadThrough.new(chapter:, user: current_user).call
      range = list_progress.read_through_label(chapter)
      render json: {
        message: t('fictions.chapters_tab.row_menu.marked_through', range:),
        undo: (undo_token(result) if result.chapter_ids.any?),
        streams: streams_for(result.chapter_ids)
      }
    end

    def destroy
      undo = self.class.verifier.verified(params[:undo].to_s, purpose: undo_purpose)
      return head(:unprocessable_content) unless undo

      undo_read_through(undo)
      render json: { streams: streams_for(undo['ids']) }
    end

    private

    attr_reader :fiction

    def set_fiction
      @fiction = Fiction.find(params.expect(:fiction_id))
    end

    def undo_token(result)
      self.class.verifier.generate({ 'ids' => result.chapter_ids, 'percent' => result.resume_percent },
                                   purpose: undo_purpose, expires_in: UNDO_TTL)
    end

    def undo_read_through(undo)
      Reading::UndoReadThrough.new(user: current_user, fiction:, chapter_ids: undo['ids'],
                                   resume_percent: undo['percent']).call
    end

    def undo_purpose = "#{current_user.id}:#{fiction.id}"

    # Loaded rows of the changed chapters: every translation of a chapter is its own row.
    def streams_for(chapter_ids)
      keys = Chapter.where(id: chapter_ids).pluck(:volume_number, :number).to_set
      rows = list_scope.where(id: row_ids).select { |chapter| keys.include?(ReadingChapterRead.chapter_key(chapter)) }
      fiction_list_streams(rows).join
    end

    def row_ids
      Array(params[:row_ids]).first(MAX_ROWS).filter_map { |id| Integer(id, exception: false) }
    end
  end
end
