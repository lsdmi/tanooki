# frozen_string_literal: true

class ScanlatorsController < ApplicationController
  include FictionQuery

  before_action :authenticate_user!, except: :show
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
      redirect_to scanlator_path(@scanlator), notice: 'Команду додано, час додати ваші твори.'
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
      redirect_to scanlator_path(@scanlator), notice: 'Команду оновлено.'
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  def destroy
    if @scanlator.destroy
      render turbo_stream: [refresh_screen, refresh_sweetalert]
    else
      render turbo_stream: update_notice(@scanlator.errors[:base].first)
    end
  end

  private

  def fiction_list
    current_user.admin? ? fiction_all_ordered_by_latest_chapter : dashboard_fiction_list
  end

  def scanlator_params
    params.require(:scanlator).permit(
      :avatar, :banner, :description, :telegram_id, :title, member_ids: []
    )
  end

  def refresh_screen
    turbo_stream.update(
      'scanlators-screen',
      partial: 'scanlators/dashboard',
      locals: { scanlators: current_user.admin? ? Scanlator.all : current_user.scanlators }
    )
  end

  def update_notice(message)
    turbo_stream.update(
      'application-alert',
      partial: 'shared/alert',
      locals: { alert: message }
    )
  end

  def set_scanlator
    @scanlator = @commentable = Scanlator.find(params[:id])
  end

  def verify_permissions
    redirect_to root_path unless current_user.admin? || current_user.scanlators.include?(@scanlator)
  end
end
