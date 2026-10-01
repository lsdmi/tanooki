# frozen_string_literal: true

# Rating helpers for {Fiction}.
module FictionRatings
  extend ActiveSupport::Concern

  def average_rating
    ratings = fiction_ratings
    if ratings.loaded?
      average_rating_from_loaded(ratings)
    else
      return 0.0 unless ratings.exists?

      ratings.average(:rating).round(1)
    end
  end

  def rating_count
    ratings = fiction_ratings
    ratings.loaded? ? ratings.size : ratings.count
  end

  # [count, average] in one query, for places that show both.
  def rating_summary
    ratings = fiction_ratings
    return [ratings.size, average_rating_from_loaded(ratings)] if ratings.loaded?

    count, average = ratings.pick(Arel.sql('COUNT(*)'), Arel.sql('AVG(rating)'))
    [count, average.to_f.round(1)]
  end

  def user_rating(user)
    return nil unless user

    ratings = fiction_ratings
    if ratings.loaded?
      ratings.find { |rating| rating.user_id == user.id }&.rating
    else
      ratings.find_by(user: user)&.rating
    end
  end

  private

  def average_rating_from_loaded(ratings)
    return 0.0 if ratings.empty?

    (ratings.sum(&:rating).to_f / ratings.size).round(1)
  end
end
