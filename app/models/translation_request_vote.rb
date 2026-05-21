# frozen_string_literal: true

# Vote cast by a user on a translation request.
class TranslationRequestVote < ApplicationRecord
  belongs_to :user
  belongs_to :translation_request, counter_cache: :votes_count

  validates :user_id, uniqueness: { scope: :translation_request_id }
end
