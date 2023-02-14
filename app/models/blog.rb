# frozen_string_literal: true

class Blog < Content
  extend FriendlyId

  friendly_id :slug_candidates

  belongs_to :user

  def slug_candidates
    [
      title.downcase
    ]
  end
end
