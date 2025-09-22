# frozen_string_literal: true

class FictionRatingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_fiction

  def create
    rating = params[:rating].to_i

    if rating < 1 || rating > 5
      render json: { error: 'Invalid rating' }, status: :unprocessable_entity
      return
    end

    fiction_rating = @fiction.fiction_ratings.find_or_initialize_by(user: current_user)
    fiction_rating.rating = rating

    if fiction_rating.save
      render json: {
        average_rating: @fiction.reload.average_rating,
        rating_count: @fiction.rating_count,
        user_rating: rating
      }
    else
      render json: { error: fiction_rating.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def update
    create # Same logic for both create and update
  end

  private

  def set_fiction
    @fiction = Fiction.find(params[:fiction_id])
  end
end
