# frozen_string_literal: true

class FictionsController < ApplicationController
  before_action :authenticate_user!, except: %i[show]
  before_action :set_fiction, only: %i[show edit update destroy]
  before_action :track_visit, :load_advertisement, only: :show
  before_action :verify_permissions, except: %i[new create show]

  def index
    # TODO:
    @hero_ad = Advertisement.find_by(slug: 'fictions-index-hero-ad')
    @popular_fictions = Fiction.order(:view)
    @most_reads = most_reads
    @latest_updates = latest_updates
  end

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
    setup_paginator
    render turbo_stream: refresh_list
  end

  private

  def most_reads
    Fiction.select('fictions.*, SUM(chapters.views) AS total_views')
           .joins(:chapters)
           .includes([{ cover_attachment: :blob }])
           .group('fictions.id')
           .order('total_views DESC')
           .limit(5)
  end

  def latest_updates
    Fiction.joins(:chapters)
           .includes([{ cover_attachment: :blob }])
           .select('fictions.*, MAX(chapters.created_at) AS max_created_at')
           .group(:fiction_id)
           .order('max_created_at DESC')
           .limit(20)
  end

  def setup_paginator
    fiction_paginator = FictionPaginator.new(@pagy, @fictions, params)
    fiction_paginator.call
    @paginators = fiction_paginator.initiate
  end

  def fiction_page
    (params[:page].to_i - 1) if Fiction.all.size <= (params[:page].to_i * 8) - 8
  end

  def fiction_params
    params.require(:fiction).permit(
      :alternative_title, :author, :cover, :description, :english_title,
      :status, :title, :translator, :total_chapters, :user_id
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
