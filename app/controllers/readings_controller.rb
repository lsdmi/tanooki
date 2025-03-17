# frozen_string_literal: true

class ReadingsController < ApplicationController
  include LibraryHelper

  before_action :authenticate_user!
  before_action :set_fiction, only: :show
  before_action :set_chapter, only: :destroy
  before_action :authorize_chapter_deletion, only: :destroy

  def show
    @pagy, @chapters = pagy(ordered_user_chapters_desc(@fiction, current_user), limit: 10)
  end

  def destroy
    stack_size = @chapter.fiction.chapters.by_user_scanlators(current_user).size
    @chapter.destroy

    handle_scanlators_destruction(stack_size)

    reload_fiction_chapters
    render turbo_stream: [refresh_list, refresh_sweetalert]
  end

  private

  def set_fiction
    @fiction = Fiction.find(params[:id])
  end

  def set_chapter
    @chapter = Chapter.find(params[:id])
  end

  def authorize_chapter_deletion
    return if current_user.admin? || current_user.chapters.include?(@chapter)

    redirect_to root_path
  end

  def handle_scanlators_destruction(stack_size)
    return unless @chapter.fiction.scanlators.size > 1 && stack_size == 1

    current_user.scanlators.each { |scanlator| destroy_association(scanlator) }
  end

  def reload_fiction_chapters
    @fiction = @chapter.fiction
    @pagy, @chapters = pagy(
      ordered_user_chapters_desc(@fiction, current_user),
      limit: 10,
      request_path: reading_path(@fiction),
      page: params[:page] || 1
    )
  end

  def refresh_list
    turbo_stream.update(
      'chapters-list',
      partial: 'chapters',
      locals: { fiction: @fiction, pagy: @pagy, chapters: @chapters }
    )
  end
end
