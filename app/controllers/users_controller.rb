# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
    @pagy, @publications = pagy(current_user.publications.order(created_at: :desc), items: 8)
    @avatars = Rails.cache.fetch('avatars', expires_in: 1.day) do
      Avatar.includes(image_attachment: :blob).order(created_at: :desc)
    end
  end

  def update_avatar
    current_user.update(avatar_id: params[:user][:avatar_id])
    redirect_to request.referer || root_path, notice: 'Портретик оновлено.'
  end
end
