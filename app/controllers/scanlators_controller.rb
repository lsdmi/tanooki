# frozen_string_literal: true

class ScanlatorsController < ApplicationController
  include FictionQuery

  before_action :authenticate_user!, except: :show
  before_action :set_common_vars, only: :index
  before_action :set_scanlator, only: %i[show edit update destroy]
  before_action :verify_permissions, only: %i[edit update destroy]

  def index
    @scanlators = current_user.admin? ? Scanlator.order(:title) : current_user.scanlators.order(:title)

    render 'users/show'
  end

  def show
    @fictions = @scanlator.fictions.includes(:chapters, :genres, cover_attachment: :blob).order(views: :desc)
    @feeds = ScanlatorFeeder.new(fiction_size: @fictions.size, scanlator: @scanlator).call
  end

  def create
    @scanlator = Scanlator.new(scanlator_params)

    if @scanlator.save
      ScanlatorUsersManager.new(scanlator_params[:member_ids], @scanlator).operate
      redirect_to scanlators_path, notice: 'Команду додано.'
    else
      render 'new', status: :unprocessable_entity
    end
  end

  def new
    @scanlator = Scanlator.new
  end

  def edit; end

  def update
    if @scanlator.update(scanlator_params)
      ScanlatorUsersManager.new(scanlator_params[:member_ids], @scanlator).operate
      redirect_to scanlators_path, notice: 'Команду оновлено.'
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  def destroy
    @scanlator.destroy
    set_common_vars
    render turbo_stream: [refresh_screen, refresh_sidebar]
  end

  private

  def fiction_list
    current_user.admin? ? fiction_all_ordered_by_latest_chapter : dashboard_fiction_list
  end

  def scanlator_params
    params.require(:scanlator).permit(
      :avatar, :banner, :telegram_id, :title, member_ids: []
    )
  end

  def refresh_screen
    turbo_stream.update(
      'scanlators-screen',
      partial: 'scanlators/dashboard',
      locals: { scanlators: current_user.admin? ? Scanlator.all : current_user.scanlators }
    )
  end

  def refresh_sidebar
    turbo_stream.update(
      'default-sidebar',
      partial: 'users/dashboard/sidebar',
      locals: { user_publications: @user_publications, fictions_size: @fictions_size }
    )
  end

  def set_common_vars
    @fictions_size = fiction_list.size.size
    @user_publications = current_user.publications.order(created_at: :desc)
  end

  def set_scanlator
    @scanlator = @commentable = Scanlator.find(params[:id])
  end

  def verify_permissions
    redirect_to root_path unless current_user.admin? || current_user.scanlators.include?(@scanlator)
  end
end
