# frozen_string_literal: true

# Rating helpers for {Fiction}.
module FictionRatings
  extend ActiveSupport::Concern

  def average_rating
    return 0.0 if fiction_ratings.empty?

    fiction_ratings.average(:rating).round(1)
  end

  def rating_count
    fiction_ratings.count
  end

  def user_rating(user)
    return nil unless user

    fiction_ratings.find_by(user: user)&.rating
  end
end
