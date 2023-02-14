# frozen_string_literal: true

class BlogsController < ApplicationController
  before_action :authenticate_user!, except: :show
  before_action :set_blog, only: %i[edit update destroy]

  def new
    @blog = Blog.new
  end

  def create
    @blog = Blog.new(blog_params)

    if @blog.save
      redirect_to root_path, notice: 'Звістку створено.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def blog_params
    params.require(:blog).permit(:title, :description, :cover, :user_id)
  end
end
