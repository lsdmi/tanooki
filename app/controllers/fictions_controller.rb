# frozen_string_literal: true

class FictionsController < ApplicationController
  before_action :authenticate_user!, except: %i[show]
  before_action :set_fiction, only: %i[show edit update destroy]
  before_action :track_visit, :load_advertisement, only: :show
  before_action :verify_permissions, except: %i[new create show]

  def show
    @comments = @fiction.comments.parents.order(created_at: :desc)
    @comment = Comment.new
  end

  def new
    @fiction = Fiction.new
  end

  def create
    @fiction = Fiction.new(fiction_params)

    if @fiction.save
      redirect_to root_path, notice: 'Твір створено.'
    else
      render 'fictions/new', status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @fiction.update(fiction_params)
      redirect_to root_path, notice: 'Твір оновлено.'
    else
      render 'fictions/edit', status: :unprocessable_entity
    end
  end

  def destroy
    @fiction.destroy
    @pagy, @fictions = pagy(
      Fiction.all.order(:title),
      items: 8,
      request_path: readings_path,
      page: fiction_page || 1
    )

    fiction_paginator = FictionPaginator.new(@pagy, @fictions, params)
    fiction_paginator.call
    @paginators = fiction_paginator.get_paginator

    render turbo_stream: refresh_list
  end

  private

  def fiction_page
    (params[:page].to_i - 1) if Fiction.all.size <= (params[:page].to_i * 8) - 8
  end

  def fiction_params
    params.require(:fiction).permit(
      :author, :cover, :description, :status, :title, :translator, :total_chapters, :user_id
    )
  end

  def set_fiction
    @fiction = @commentable = Fiction.find(params[:id])
  end

  def refresh_list
    turbo_stream.update(
      'fictions-list',
      partial: 'users/dashboard/fictions',
      locals: { fictions: @fictions, pagy: @pagy }
    )
  end

  def verify_permissions
    redirect_to root_path unless current_user.admin? || current_user.fictions.include?(@fiction)
  end
end
