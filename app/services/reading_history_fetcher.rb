# frozen_string_literal: true

class ReadingHistoryFetcher
  def initialize(user)
    @user = user
  end

  def call
    @user.readings.includes(
      fiction: [:cover_attachment, { scanlators: :avatar_attachment }]
    ).order(updated_at: :desc)
  end
end
