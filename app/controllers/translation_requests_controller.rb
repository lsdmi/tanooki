# frozen_string_literal: true

class TranslationRequestsController < ApplicationController
  before_action :authenticate_user!, only: :create
  before_action :load_advertisement

  def index
    @translation_requests = TranslationRequest.includes(:user).by_creation_date
    @translation_request = TranslationRequest.new
  end

  def create
    @translation_request = current_user.translation_requests.build(translation_request_params)

    if @translation_request.save
      redirect_to translation_requests_path, notice: 'Запит на переклад успішно надіслано!'
    else
      @translation_requests = TranslationRequest.includes(:user).by_creation_date
      render :index, status: :unprocessable_entity
    end
  end

  private

  def translation_request_params
    params.require(:translation_request).permit(:title, :author, :source_url, :notes)
  end
end
