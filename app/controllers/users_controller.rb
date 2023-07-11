# frozen_string_literal: true

class UsersController < ApplicationController
  include FictionQuery

  before_action :authenticate_user!
  before_action :set_common_vars, only: %i[show avatars blogs readings]

  def show
    @pagy, @publications = pagy(@user_publications, items: 8)
  end

  def update_avatar
    current_user.update(avatar_id: params[:user][:avatar_id])
    redirect_to request.referer || root_path, notice: 'Портретик оновлено.'
  end

  def avatars
    @avatars = fetch_avatars
    render_dashboard('users/dashboard/avatars')
  end

  def blogs
    @pagy, @publications = pagy(@user_publications, items: 8)
    render_dashboard('users/dashboard/blogs')
  end

  def readings
    @pagy, @fictions = pagy(fiction_list, items: 8)
    @random_reading = Fiction.all.sample
    fiction_paginator = FictionPaginator.new(@pagy, @fictions, params)
    fiction_paginator.call
    @paginators = fiction_paginator.initiate
    render_dashboard('users/dashboard/readings', params[:false_remote])
  end

  private

  def fiction_list
    current_user.admin? ? fiction_all_ordered_by_latest_chapter : dashboard_fiction_list
  end

  def set_common_vars
    @fictions_size = fiction_list.size.size
    @user_publications = current_user.publications.order(created_at: :desc)
  end

  def fetch_avatars
    Rails.cache.fetch('avatars', expires_in: 1.day) do
      Avatar.includes(image_attachment: :blob).order(created_at: :desc)
    end
  end

  def render_dashboard(partial, false_remote = nil)
    if false_remote
      render 'show'
    else
      render turbo_stream: [
        turbo_stream.replace('section', partial:),
        update_sidebar
      ].compact
    end
  end

  def update_sidebar
    turbo_stream.replace('default-sidebar', partial: 'users/dashboard/sidebar')
  end
end
