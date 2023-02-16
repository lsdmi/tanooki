# frozen_string_literal: true

module Admin
  class TalesController < ApplicationController
    before_action :authenticate_user!, :verify_user_permissions
    before_action :set_tale, only: %i[edit destroy]

    def index
      @tales = Tale.all.order(created_at: :desc)
    end

    def new
      @publication = Tale.new
    end

    def edit; end

    def destroy
      @tale.destroy
      redirect_to root_path, notice: 'Звістку видалено.'
    end

    private

    def set_tale
      @publication = Tale.find(params[:id])
    end

    def tale_params
      params.require(:tale).permit(:title, :description, :cover, :highlight)
    end

    def verify_user_permissions
      redirect_to root_path unless current_user.admin?
    end
  end
end
