# frozen_string_literal: true

class ProfilesController < ApplicationController
  before_action :set_user, only: :show
  before_action :pokemon_appearance, only: [:show]

  def show
    # The user is already set by the before_action
    # Additional logic for profile display can be added here
  end

  private

  def set_user
    @user = User.find_by_sqid(params[:id])

    return if @user

    redirect_to root_path
  end
end
