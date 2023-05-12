# frozen_string_literal: true

module Admin
  class ChaptersController < ApplicationController
    before_action :authenticate_user!, :verify_user_permissions
    before_action :set_chapter, only: %i[edit update destroy]

    def new
      @chapter = Chapter.new
    end

    def create
      @chapter = Chapter.new(chapter_params)

      if @chapter.save
        redirect_to admin_fictions_path, notice: 'Розділ додано.'
      else
        render 'admin/chapters/new', status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @chapter.update(chapter_params)
        redirect_to admin_fictions_path, notice: 'Розділ оновлено.'
      else
        render 'admin/chapters/edit', status: :unprocessable_entity
      end
    end

    def destroy
      @chapter.destroy
      chapter_page = params["chapter_page_#{@chapter.fiction.slug}"]
      chapter_page = (chapter_page.to_i - 1) if chapters.size <= (chapter_page.to_i * 8) - 8
      setup_pagination(chapters, chapter_page)
      render turbo_stream: refresh_list
    end

    private

    def chapters
      @chapter.fiction.chapters.order(number: :desc)
    end

    def setup_pagination(chapters, chapter_page)
      @pagination = pagy(
        chapters,
        page: chapter_page,
        items: 8,
        request_path:,
        page_param: "chapter_page_#{@chapter.fiction.slug}"
      )
    end

    def request_path
      admin_fictions_path
    end

    def chapter_params
      params.require(:chapter).permit(
        :content, :fiction_id, :number, :title, :user_id
      )
    end

    def set_chapter
      @chapter = Chapter.find(params[:id])
    end

    def refresh_list
      turbo_stream.update(
        "chapter-list-#{@chapter.fiction.slug}",
        partial: 'admin/fictions/chapter_list',
        locals: { fiction: @chapter.fiction, pagination: @pagination }
      )
    end
  end
end
