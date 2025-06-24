# frozen_string_literal: true

class ReadingHistoryFetcher
  def initialize(user)
    @user = user
  end

  def call
    @user.readings.includes(
      [{ fiction: :cover_attachment }, :chapter]
    ).order(updated_at: :desc)
  end
end
