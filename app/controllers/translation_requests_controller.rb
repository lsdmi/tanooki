# frozen_string_literal: true

class TranslationRequestsController < ApplicationController
  before_action :authenticate_user!, only: %i[create update assign unassign destroy]
  before_action :load_advertisement
  before_action :set_translation_request, only: %i[update assign unassign destroy]

  def index
    @pagy, @translation_requests = pagy(
      TranslationRequest.includes(:user, :translation_request_votes, :scanlator).by_votes,
      limit: 3
    )
    @total_requests_count = TranslationRequest.count
    @translation_request = TranslationRequest.new

    respond_to do |format|
      format.html
      format.turbo_stream { render_requests_list }
    end
  end

  def create
    @translation_request = current_user.translation_requests.build(translation_request_params)

    if @translation_request.save
      redirect_to translation_requests_path, notice: 'Запит на переклад успішно надіслано!'
    else
      @pagy, @translation_requests = pagy(
        TranslationRequest.includes(:user, :translation_request_votes, :scanlator).by_votes,
        limit: 3
      )
      @total_requests_count = TranslationRequest.count
      render :index, status: :unprocessable_entity
    end
  end

  def update
    if @translation_request.update(translation_request_params)
      respond_to do |format|
        format.html { redirect_to translation_requests_path, notice: 'Запит на переклад успішно оновлено!' }
        format.json { render json: { success: true, message: 'Запит успішно оновлено!' } }
      end
    else
      respond_to do |format|
        format.html { redirect_to translation_requests_path, alert: 'Помилка при оновленні запиту.' }
        format.json { render json: { success: false, errors: @translation_request.errors.full_messages } }
      end
    end
  end

  def assign
    scanlator = current_user.scanlators.find(params[:scanlator_id])

    if @translation_request.scanlator_id.present?
      render json: { error: 'Цей запит вже призначено іншій команді перекладачів' }, status: :unprocessable_entity
      return
    end

    if @translation_request.update(scanlator: scanlator)
      render json: {
        success: true,
        message: 'Запит успішно призначено команді',
        scanlator_title: scanlator.title
      }
    else
      render json: { error: 'Не вдалося призначити запит' }, status: :unprocessable_entity
    end
  end

  def unassign
    if @translation_request.update(scanlator: nil)
      render json: {
        success: true,
        message: 'Запит успішно відкликано від команди'
      }
    else
      render json: { error: 'Не вдалося відкликати запит' }, status: :unprocessable_entity
    end
  end

  def destroy
    if @translation_request.destroy
      respond_to do |format|
        format.html { redirect_to translation_requests_path, notice: 'Запит на переклад успішно видалено!' }
        format.json { render json: { success: true, message: 'Запит успішно видалено!' } }
      end
    else
      respond_to do |format|
        format.html { redirect_to translation_requests_path, alert: 'Помилка при видаленні запиту.' }
        format.json do
          render json: { success: false, error: 'Не вдалося видалити запит' }, status: :unprocessable_entity
        end
      end
    end
  end

  private

  def translation_request_params
    params.require(:translation_request).permit(:title, :author, :source_url, :notes)
  end

  def set_translation_request
    @translation_request = TranslationRequest.find(params[:id])
  end

  def render_requests_list
    render turbo_stream: turbo_stream.update(
      'requests-container',
      partial: 'translation_requests/requests_list',
      locals: {
        translation_requests: @translation_requests,
        pagy: @pagy,
        total_requests_count: @total_requests_count
      }
    )
  end
end
