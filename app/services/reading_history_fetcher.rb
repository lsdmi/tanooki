# frozen_string_literal: true

# Loads a user's readings with fiction and scanlator data.
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
