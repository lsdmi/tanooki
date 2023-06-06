# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
    @fictions_size = Fiction.all.size
    blog_vars
  end

  def update_avatar
    current_user.update(avatar_id: params[:user][:avatar_id])
    redirect_to request.referer || root_path, notice: 'Портретик оновлено.'
  end

  def avatars
    avatar_vars
    render turbo_stream: [
      turbo_stream.replace('section', partial: 'users/dashboard/avatars'),
      update_sidebar
    ]
  end

  def blogs
    blog_vars
    render turbo_stream: [
      turbo_stream.replace('section', partial: 'users/dashboard/blogs'),
      update_sidebar
    ]
  end

  def readings
    readings_vars

    if params[:false_remote]
      render 'show'
    else
      render turbo_stream: [
        turbo_stream.replace('section', partial: 'users/dashboard/readings'),
        update_sidebar
      ]
    end
  end

  private

  def blog_vars
    @fictions_size = Fiction.all.size
    @user_publicatons = current_user.publications.order(created_at: :desc)
    @pagy, @publications = pagy(@user_publicatons, items: 8)
  end

  def avatar_vars
    @fictions_size = Fiction.all.size
    @user_publicatons = current_user.publications.order(created_at: :desc)
    @avatars = Rails.cache.fetch('avatars', expires_in: 1.day) do
      Avatar.includes(image_attachment: :blob).order(created_at: :desc)
    end
  end

  def readings_vars
    @fictions_size = Fiction.all.size
    @user_publicatons = current_user.publications.order(created_at: :desc)
    @pagy, @fictions = pagy(Fiction.order(:title), items: 8)
    @random_reading = @fictions.sample
    fiction_paginator = FictionPaginator.new(@pagy, @fictions, params)
    fiction_paginator.call
    @paginators = fiction_paginator.initiate
  end

  def update_sidebar
    turbo_stream.replace('default-sidebar', partial: 'users/dashboard/sidebar')
  end
end
