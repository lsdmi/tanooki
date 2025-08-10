# frozen_string_literal: true

class ScanlatorsController < ApplicationController
  include FictionQuery

  before_action :require_authentication, except: :show
  before_action :set_scanlator, only: %i[show edit update destroy]
  before_action :verify_permissions, only: %i[edit update destroy]
  before_action :pokemon_appearance, only: [:show]

  def index
    session[:studio_tab] = 'teams'
    redirect_to studio_index_path
  end

  def show
    @fictions = @scanlator.fictions.most_reads.includes(%i[cover_attachment genres])
  end

  def create
    @scanlator = Scanlator.new(scanlator_params)

    if @scanlator.save
      ScanlatorUsersManager.new(scanlator_params[:member_ids], @scanlator).operate
      redirect_to scanlator_path(@scanlator), notice: 'Команду додано, час додати ваші твори.'
    else
      render 'new', status: :unprocessable_content
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
      render 'edit', status: :unprocessable_content
    end
  end

  def destroy
    @scanlator.destroy
    @pagy, @scanlators = pagy(
      scanlators_scope,
      limit: 8,
      request_path: scanlators_path,
      page: params[:page] || 1
    )

    render turbo_stream: [refresh_list, refresh_sweetalert]
  end

  private

  def scanlator_params
    params.require(:scanlator).permit(
      :avatar, :banner, :bank_url, :description, :convertable, :extra_url, :telegram_id, :title, member_ids: []
    )
  end

  def refresh_list
    turbo_stream.update(
      'scanlators-list',
      partial: 'scanlators/team_grid',
      locals: { scanlators: @scanlators, pagy: @pagy }
    )
  end

  def scanlators_scope
    if Current.user.admin?
      Scanlator.includes(:avatar_attachment).order(:title)
    else
      user.scanlators.includes(:avatar_attachment).order(:title)
    end
  end

  def set_scanlator
    @scanlator = Scanlator.find(params[:id])
  end

  def verify_permissions
    redirect_to root_path unless Current.user.admin? || Current.user.scanlators.include?(@scanlator)
  end
end
