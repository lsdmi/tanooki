# frozen_string_literal: true

# Handles translation team pages and authenticated team management.
class ScanlatorsController < ApplicationController
  helper Scanlators::SelectOptionsHelper

  include FictionQuery

  before_action :authenticate_user!, except: :show
  before_action :set_scanlator, only: %i[show edit update destroy]
  before_action :verify_permissions, only: %i[edit update destroy]
  before_action :pokemon_appearance, only: [:show]

  def index
    session[:studio_tab] = 'teams'
    redirect_to studio_index_path
  end

  def show
    @scanlator_stats = Scanlators::ShowPresenter.new(@scanlator)
    @fictions = @scanlator.fictions.most_reads.includes(%i[cover_attachment genres])
  end

  def new
    @scanlator = Scanlator.new
  end

  def edit; end

  def create
    @scanlator = Scanlator.new(scanlator_params)
    ensure_creator_in_member_ids unless current_user.admin?

    if @scanlator.save
      Scanlators::SyncMembers.new(
        scanlator_params[:member_ids], @scanlator, user: current_user, initial: true
      ).call
      redirect_to scanlator_path(@scanlator), notice: t('scanlators.notices.create_success')
    else
      render 'new', status: :unprocessable_content
    end
  end

  def update
    if @scanlator.update(scanlator_params)
      Scanlators::SyncMembers.new(scanlator_params[:member_ids], @scanlator, user: current_user).call
      redirect_to scanlator_path(@scanlator), notice: t('scanlators.notices.update_success')
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

    render turbo_stream: refresh_list
  end

  private

  def scanlator_params
    params.expect(
      scanlator: [
        :avatar, :banner, :bank_url, :description, :notice, :convertable, :extra_url, :telegram_id, :title,
        { member_ids: [] }
      ]
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
    if current_user.admin?
      Scanlator.includes(:avatar_attachment).order(:title)
    else
      current_user.scanlators.includes(:avatar_attachment).order(:title)
    end
  end

  def set_scanlator
    @scanlator = Scanlator.find(params[:id])
  end

  def verify_permissions
    redirect_to root_path unless current_user.admin? || current_user.scanlators.include?(@scanlator)
  end

  def ensure_creator_in_member_ids
    ids = Array(@scanlator.member_ids).map(&:to_i)
    return if ids.include?(current_user.id)

    @scanlator.member_ids = (ids + [current_user.id]).map(&:to_s)
  end
end
