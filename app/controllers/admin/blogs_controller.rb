# frozen_string_literal: true

module Admin
  class BlogsController < ApplicationController
    before_action :authenticate_user!, :verify_user_permissions
    before_action :set_tale, only: %i[edit update]

    def index
      @blogs = Blog.created
    end

    def edit; end

    def update
      if @publication.update(blog_params)
        redirect_to update_redirect_path, notice: 'допис відмодеровано'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_tale
      @publication = Blog.find(params[:id])
    end

    def blog_params
      params.require(:publication).permit(:status, :status_message)
    end

    def verify_user_permissions
      redirect_to root_path unless current_user.admin?
    end

    def update_redirect_path
      @publication.approved? ? blog_path(@publication) : admin_blogs_path
    end
  end
end
