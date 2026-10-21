# frozen_string_literal: true

# A genre an account asked to drop from discovery lists. Rating pills are not genres.
class UserHiddenGenre < ApplicationRecord
  MAX_PER_USER = 30

  belongs_to :user, inverse_of: :hidden_genres
  belongs_to :genre

  attr_accessor :skip_cap

  validates :genre_id, uniqueness: { scope: :user_id }
  validate :genre_is_not_a_rating
  validate :within_cap, on: :create, unless: :skip_cap

  private

  def genre_is_not_a_rating
    return if genre.nil?
    return unless Genre.rating_tag?(genre.name)

    errors.add(:genre, :rating_label)
  end

  def within_cap
    return if user.nil?
    return if user.hidden_genres.where.not(id:).count < MAX_PER_USER

    errors.add(:base, :too_many_genres)
  end
end
