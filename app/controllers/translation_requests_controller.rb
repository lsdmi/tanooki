# frozen_string_literal: true

# Handles community translation requests, assignment, editing, and deletion.
class TranslationRequestsController < ApplicationController
  include TranslationRequestsResponses

  before_action :authenticate_user!, only: %i[create update assign unassign destroy]
  before_action :load_advertisement
  before_action :set_translation_request, only: %i[update assign unassign destroy]
  before_action :authorize_translation_request_owner!, only: %i[update destroy]

  def index
    load_index_data
    @translation_request = TranslationRequest.new

    respond_to do |format|
      format.html
      format.turbo_stream { render_requests_list }
    end
  end

  def create
    @translation_request = current_user.translation_requests.build(translation_request_params)

    if @translation_request.save
      redirect_to translation_requests_path, notice: t('translation_requests.notices.create_success')
    else
      handle_create_failure
    end
  end

  def update
    if @translation_request.update(translation_request_params)
      handle_update_success
    else
      handle_update_failure
    end
  end

  def assign
    scanlator = current_user.scanlators.find(params[:scanlator_id])

    return render_already_assigned_error if @translation_request.scanlator_id.present?

    if @translation_request.update(scanlator: scanlator)
      render_assign_success(scanlator)
    else
      render_assign_error
    end
  end

  def unassign
    if @translation_request.update(scanlator: nil)
      render json: {
        success: true,
        message: t('translation_requests.messages.unassign_success')
      }
    else
      render json: { error: t('translation_requests.alerts.unassign_error') }, status: :unprocessable_content
    end
  end

  def destroy
    if @translation_request.destroy
      handle_destroy_success
    else
      handle_destroy_failure
    end
  end

  private

  def translation_request_params
    params.expect(translation_request: %i[title author source_url notes])
  end

  def set_translation_request
    @translation_request = TranslationRequest.find(params[:id])
  end

  def authorize_translation_request_owner!
    return if current_user.admin? || current_user.translation_requests.exists?(id: @translation_request.id)

    head :forbidden
  end
end
