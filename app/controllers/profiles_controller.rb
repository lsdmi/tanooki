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
    @recent_publications = @user.publications.includes(:cover_attachment, :rich_text_description).recent.limit(3)
    @user_scanlators = @user.scanlators
    @recent_comments = @user.comments.order(created_at: :desc).includes(:commentable).limit(3)
    @recent_readings = @user.readings.includes(fiction: :cover_attachment,
                                               chapter: {}).order(updated_at: :desc).limit(4)
    @user_bookshelves = @user.bookshelves.includes(:fictions).most_viewed.limit(1)
  end

  def load_pokemon_stats
    @pokemon_count = @user.pokemons.count
    @total_pokemon = Pokemon.where(descendant_level: 0).count
    @victories = calculate_victories
    @total_battles = calculate_total_battles
    @user_rating = User.dex_leaders.index(@user) + 1
  end

  def calculate_victories
    @user.attacker_battle_logs.where(winner: @user).count +
      @user.defender_battle_logs.where(winner: @user).count
  end

  def calculate_total_battles
    @user.attacker_battle_logs.count + @user.defender_battle_logs.count
  end
end
