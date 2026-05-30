# frozen_string_literal: true

# Authenticated create/update of a user's 1–5 star rating for a fiction.
class FictionRatingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_fiction

  def create
    rating = requested_rating
    return render_invalid_rating unless valid_rating?(rating)

    save_fiction_rating(rating)
  end

  def update
    create # Same logic for both create and update
  end

  private

  def set_fiction
    @fiction = Fiction.find(params[:fiction_id])
  end

  def requested_rating
    params[:rating].to_i
  end

  def valid_rating?(rating)
    rating.between?(1, 5)
  end

  def render_invalid_rating
    render json: { error: 'Invalid rating' }, status: :unprocessable_content
  end

  def save_fiction_rating(rating)
    fiction_rating = @fiction.fiction_ratings.find_or_initialize_by(user: current_user)
    fiction_rating.rating = rating

    if fiction_rating.save
      render json: fiction_rating_summary(rating)
    else
      render json: { error: fiction_rating.errors.full_messages.join(', ') }, status: :unprocessable_content
    end
  end

  def fiction_rating_summary(rating)
    {
      average_rating: @fiction.reload.average_rating,
      rating_count: @fiction.rating_count,
      user_rating: rating
    }
  end
end
