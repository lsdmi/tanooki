# frozen_string_literal: true

class ChaptersController < ApplicationController
  before_action :set_chapter, :track_visit
  before_action :load_advertisement

  def show
    @comments = @chapter.comments.parents.order(created_at: :desc)
    @comment = Comment.new
    @next_chapter = next_chapter
    @more_ads = Advertisement.includes([{ cover_attachment: :blob }]).excluding(@advertisement).enabled.sample
  end

  private

  def set_chapter
    @chapter = @commentable = Chapter.find(params[:id])
  end

  def next_chapter
    @chapter.fiction.chapters.where('number > ?', @chapter.number).order(:number).first
  end
end
