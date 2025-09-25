# frozen_string_literal: true

class TranslationRequestVote < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :translation_request

  # Validations
  validates :user_id, uniqueness: { scope: :translation_request_id,
                                    message: 'можна голосувати за запит лише один раз' }

  # Callbacks to update vote count on translation request
  after_commit :update_translation_request_votes_count, on: %i[create destroy]

  private

  def update_translation_request_votes_count
    return unless translation_request

    votes_count = translation_request.translation_request_votes.count
    translation_request.update_column(:votes_count, votes_count)
  end
end
