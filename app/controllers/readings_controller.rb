# frozen_string_literal: true

# User reading list: add, remove, and browse tracked fictions.
class ReadingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_fiction, only: :show
  before_action :set_chapter, only: :destroy
  before_action :authorize_chapter_deletion, only: :destroy

  def show
    redirect_to root_path unless current_user.manages_fiction?(@fiction)

    @pagy, @chapters = pagy(
      Library::ChapterCatalog.ordered_user_chapters_desc(@fiction, current_user),
      limit: 36
    )
  end

  def destroy
    stack_size = @chapter.fiction.chapters.by_user_scanlators(current_user).size
    @chapter.destroy

    handle_scanlators_destruction(stack_size)

    reload_fiction_chapters
    render turbo_stream: turbo_stream_destroy_success(refresh_list, t('chapters.notices.destroy_success'))
  end

  private

  def set_fiction
    @fiction = Fiction.friendly.find(params[:id])
  end

  def set_chapter
    scope = current_user.admin? ? Chapter : current_user.chapters
    @chapter = scope.friendly.find(params[:id])
  end

  def authorize_chapter_deletion
    return if current_user.manages_chapter?(@chapter)

    redirect_to root_path
  end

  def handle_scanlators_destruction(stack_size)
    return unless @chapter.fiction.scanlators.size > 1 && stack_size == 1

    current_user.scanlators.each do |scanlator|
      Fictions::ScanlatorAssociationRemover.new(@chapter.fiction, scanlator).call
    end
  end

  def reload_fiction_chapters
    @fiction = @chapter.fiction
    @pagy, @chapters = pagy(
      Library::ChapterCatalog.ordered_user_chapters_desc(@fiction, current_user),
      limit: 36,
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
