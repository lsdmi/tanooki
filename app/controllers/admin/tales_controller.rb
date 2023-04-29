# frozen_string_literal: true

module Admin
  class TalesController < ApplicationController
    before_action :authenticate_user!, :verify_user_permissions
    before_action :set_tale, only: %i[edit destroy]
    before_action :set_tags, only: %i[new edit]

    def index
      @pagy, @tales = pagy(Tale.order(created_at: :desc), items: 9)
    end

    def new
      @publication = Tale.new
    end

    def edit; end

    private

    def set_tags
      @tags = Tag.all.order(:name)
    end

    def set_tale
      @publication = Tale.find(params[:id])
    end

    def tale_params
      params.require(:tale).permit(:title, :description, :cover, :highlight)
    end
  end
end
