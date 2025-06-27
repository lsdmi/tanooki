# frozen_string_literal: true

class UserUpdateService
  def initialize(user, params)
    @user = user
    @params = params
  end

  def call
    if update_user
      ServiceResult.new(success: true, data: { avatars: fetch_avatars })
    else
      ServiceResult.new(success: false, data: { avatars: fetch_avatars })
    end
  end

  private

  attr_reader :user, :params

  def update_user
    user.update(name: params[:name]) && user.update(avatar_id: params[:avatar_id])
  end

  def fetch_avatars
    Rails.cache.fetch('avatars', expires_in: 1.day) do
      Avatar.includes(:image_attachment).order(created_at: :desc)
    end
  end
end
