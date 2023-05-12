# frozen_string_literal: true

module Admin
  class FictionsController < ApplicationController
    before_action :authenticate_user!, :verify_user_permissions
    before_action :set_fiction, only: %i[edit update destroy]

    def index
      @pagy, @fictions = pagy(Fiction.order(created_at: :desc), items: 8)
      setup_paginators
    end

    def new
      @fiction = Fiction.new
    end

    def create
      @fiction = Fiction.new(fiction_params)

      if @fiction.save
        redirect_to root_path, notice: 'Твір створено.'
      else
        render 'admin/fictions/new', status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @fiction.update(fiction_params)
        redirect_to root_path, notice: 'Твір оновлено.'
      else
        render 'admin/fictions/edit', status: :unprocessable_entity
      end
    end

    def destroy
      @fiction.destroy
      @pagy, @fictions = pagy(
        fictions,
        items: 8,
        request_path:,
        page: params[:page] || 1
      )

      render turbo_stream: refresh_list
    end

    private

    def fictions
      if request.referer&.include?('admin/fictions')
        Fiction.all.order(created_at: :desc)
      else
        current_user.fictions.order(created_at: :desc)
      end
    end

    def request_path
      admin_fictions_path
    end

    def fiction_params
      params.require(:fiction).permit(
        :author, :cover, :description, :status, :title, :translator, :total_chapters, :user_id
      )
    end

    def set_fiction
      @fiction = Fiction.find(params[:id])
    end

    def refresh_list
      turbo_stream.update(
        'fictions-list',
        partial: 'list',
        locals: { fictions: @fictions, pagy: @pagy }
      )
    end

    def setup_paginators
      @paginators = {}
      @fictions.each do |fiction|
        instance_variable_set(paginated_chapters_name(fiction), paginated_chapters(fiction, params))
        instance_variable_set(fictions_name(fiction), fiction)
        @paginators[fiction.slug] = {
          paginated_chapters: instance_variable_get(paginated_chapters_name(fiction)),
          fictions: instance_variable_get(fictions_name(fiction))
        }
      end
    end

    def paginated_chapters_name(fiction)
      "@paginated_chapters_#{fiction.slug.gsub('-', '_')}"
    end

    def fictions_name(fiction)
      "@fictions_#{fiction.slug.gsub('-', '_')}"
    end

    def paginated_chapters(fiction, params)
      pagy(
        fiction.chapters.order(number: :desc),
        page: params["chapter_page_#{fiction.slug}"],
        items: 8,
        page_param: "chapter_page_#{fiction.slug}"
      )
    end
  end
end
