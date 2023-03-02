# frozen_string_literal: true

module Admin
  class AdvertisementsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_advertisement, only: %i[edit update]
    before_action :verify_user_permissions

    def index
      @advertisements = Advertisement.order(created_at: :desc)
    end

    def new
      @advertisement = Advertisement.new
    end

    def edit; end

    def create
      @advertisement = Advertisement.new(advertisement_params)

      if @advertisement.save
        redirect_to root_path, notice: 'оголошення створено'
      else
        render 'admin/advertisements/new', status: :unprocessable_entity
      end
    end

    def update
      if @advertisement.update(advertisement_params)
        redirect_to root_path, notice: 'оголошення оновлено'
      else
        render 'admin/advertisements/edit', status: :unprocessable_entity
      end
    end

    private

    def set_advertisement
      @advertisement = Advertisement.find(params[:id])
    end

    def verify_user_permissions
      redirect_to root_path unless current_user.admin?
    end

    def advertisement_params
      params.require(:advertisement).permit(:caption, :description, :cover, :resource, :enabled)
    end
  end
end
