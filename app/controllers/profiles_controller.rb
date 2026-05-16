# frozen_string_literal: true

class ProfilesController < ApplicationController
  before_action :set_user, only: :show
  before_action :pokemon_appearance, only: [:show]

  def show
    load_user_data
    load_pokemon_stats
  end

  private

  def set_user
    @user = User.find_by_sqid(params[:id])

    return if @user

    redirect_to root_path
  end

  def load_user_data
    @user.profile_show_assignments.each do |name, value|
      instance_variable_set(:"@#{name}", value)
    end
  end

  def load_pokemon_stats
    @user.profile_pokemon_stats.each do |name, value|
      instance_variable_set(:"@#{name}", value)
    end
  end
end
