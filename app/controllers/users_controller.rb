# frozen_string_literal: true

class UsersController < ApplicationController
  def update_avatar
    current_user.update(avatar_id: params[:user][:avatar_id])
    redirect_to request.referer || root_path, notice: 'Аватар оновлено.'
  end
end
