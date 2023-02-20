# frozen_string_literal: true

class BlogsController < ApplicationController
  before_action :authenticate_user!, except: :show
  before_action :set_blog, only: %i[edit show destroy]
  before_action :verify_user_permissions, only: %i[edit destroy]

  def index
    @blogs = Blog.where(user_id: current_user.id).order(created_at: :desc)
  end

  def new
    @publication = Blog.new
  end

  def edit; end

  def show
    @more_tales = Tale.all.order(created_at: :desc).first(4)
    @comments = @publication.comments.parents.order(created_at: :desc)
    @comment = Comment.new
  end

  private

  def set_blog
    @publication = Blog.find(params[:id])
  end

  def verify_user_permissions
    redirect_to root_path unless @publication.user_id == current_user.id
  end
end
