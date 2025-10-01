# frozen_string_literal: true

class TranslationRequestVote < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :translation_request, counter_cache: :votes_count

  # Validations
  validates :user_id, uniqueness: { scope: :translation_request_id,
                                    message: 'можна голосувати за запит лише один раз' }
end
