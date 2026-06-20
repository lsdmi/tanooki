# frozen_string_literal: true

# Response and index-loading helpers for TranslationRequestsController.
module TranslationRequestsResponses
  extend ActiveSupport::Concern

  private

  def handle_create_failure
    load_index_data
    render :index, status: :unprocessable_content
  end

  def handle_update_success
    respond_to do |format|
      format.html { redirect_to translation_requests_path, notice: t('translation_requests.notices.update_success') }
      format.json { render json: { success: true, message: t('translation_requests.messages.update_success') } }
    end
  end

  def handle_update_failure
    respond_to do |format|
      format.html { redirect_to translation_requests_path, alert: t('translation_requests.alerts.update_error') }
      format.json { render json: { success: false, errors: @translation_request.errors.full_messages } }
    end
  end

  def render_already_assigned_error
    render json: { error: t('translation_requests.alerts.already_assigned') }, status: :unprocessable_content
  end

  def render_assign_success(scanlator)
    render json: {
      success: true,
      message: t('translation_requests.messages.assign_success'),
      scanlator_title: scanlator.title
    }
  end

  def render_assign_error
    render json: { error: t('translation_requests.alerts.assign_error') }, status: :unprocessable_content
  end

  def handle_destroy_success
    respond_to do |format|
      format.html { redirect_to translation_requests_path, notice: t('translation_requests.notices.destroy_success') }
      format.json { render json: { success: true, message: t('translation_requests.messages.destroy_success') } }
    end
  end

  def handle_destroy_failure
    respond_to do |format|
      format.html { redirect_to translation_requests_path, alert: t('translation_requests.alerts.destroy_error') }
      format.json do
        render json: { success: false, error: t('translation_requests.alerts.destroy_json_error') },
               status: :unprocessable_content
      end
    end
  end

  def load_index_data
    @newest_request = newest_translation_request
    @pagy, @translation_requests = pagy(remaining_translation_requests, limit: 5)
    @total_requests_count = TranslationRequest.count
    @second_advertisement = second_advertisement
    @showcase_fiction = Fictions::IndexVariablesManager.showcase.sample
  end

  def newest_translation_request
    TranslationRequest.includes(:user, :scanlator).order(created_at: :desc).first
  end

  def remaining_translation_requests
    requests = TranslationRequest.includes(:user, :scanlator).by_votes
    @newest_request ? requests.where.not(id: @newest_request.id) : requests
  end

  def second_advertisement
    Advertisement.includes(%i[cover_attachment poster_attachment]).enabled.where.not(id: @advertisement.id).sample
  end

  def render_requests_list
    render turbo_stream: turbo_stream_list_refresh(requests_list_stream)
  end

  def requests_list_stream
    turbo_stream.update(
      'requests-container',
      partial: 'translation_requests/requests_list',
      locals: requests_list_locals
    )
  end

  def requests_list_locals
    {
      translation_requests: @translation_requests,
      pagy: @pagy,
      total_requests_count: @total_requests_count
    }
  end
end
