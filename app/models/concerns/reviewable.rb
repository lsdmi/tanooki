# frozen_string_literal: true

# Reviews of a fiction ({FictionReview}): comments its readers marked as reviews. The count is `reviews_count`.
module Reviewable
  extend ActiveSupport::Concern

  included do
    has_many :fiction_reviews, dependent: :destroy
  end
end
