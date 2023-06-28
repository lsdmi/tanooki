# frozen_string_literal: true

class ChaptersController < ApplicationController
  before_action :authenticate_user!, except: %i[show]
  before_action :set_chapter, only: %i[show edit update destroy]
  before_action :track_visit, :load_advertisement, only: :show
  before_action :verify_permissions, except: %i[new create show]

  def show
    @comments = @chapter.comments.parents.order(created_at: :desc)
    @comment = Comment.new
    @next_chapter = next_chapter
    @more_from_author = more_from_author
  end

  def new
    @chapter = Chapter.new
  end

  def create
    @chapter = Chapter.new(chapter_params)

    if @chapter.save
      redirect_to readings_path(false_remote: true), notice: 'Розділ додано.'
    else
      render 'chapters/new', status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @chapter.update(chapter_params)
      redirect_to dashboard_path, notice: 'Розділ оновлено.'
    else
      render 'chapters/edit', status: :unprocessable_entity
    end
  end

  def destroy
    @chapter.destroy
    chapter_page = params["chapter_page_#{@chapter.fiction_slug}"]
    chapter_page = (chapter_page.to_i - 1) if chapters.size <= (chapter_page.to_i * 8) - 8
    setup_pagination(chapters, chapter_page)
    render turbo_stream: refresh_list
  end

  private

  def more_from_author
    Rails.cache.fetch("more_from_author_#{@chapter.id}}", expires_in: 12.hours) do
      Fiction.joins(:chapters)
             .includes([{ cover_attachment: :blob }])
             .where(translator: @chapter.translator)
             .excluding(@chapter.fiction)
             .select('fictions.*, MAX(chapters.created_at) AS max_created_at')
             .group(:fiction_id)
             .order('max_created_at DESC')
    end
  end

  def set_chapter
    @chapter = @commentable = Chapter.find(params[:id])
  end

  def next_chapter
    @chapter.fiction.chapters.where('number > ?', @chapter.number).order(:number).first
  end

  def chapters
    @chapter.fiction.chapters.order(number: :desc)
  end

  def setup_pagination(chapters, chapter_page)
    return if chapter_page && chapter_page.to_i < 1

    @pagination = pagy(
      chapters,
      page: chapter_page,
      items: 8,
      request_path: readings_path,
      page_param: "chapter_page_#{@chapter.fiction_slug}"
    )
  end

  def chapter_params
    params.require(:chapter).permit(
      :content, :fiction_id, :number, :title, :user_id
    )
  end

  def refresh_list
    turbo_stream.update(
      "chapter-list-#{@chapter.fiction_slug}",
      partial: 'users/dashboard/chapter_list',
      locals: { fiction: @chapter.fiction, pagination: @pagination }
    )
  end

  def verify_permissions
    redirect_to root_path unless current_user.admin? || current_user.chapters.include?(@chapter)
  end
end
