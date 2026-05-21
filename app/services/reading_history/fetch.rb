# frozen_string_literal: true

module ReadingHistory
  # Loads a user's readings with fiction and scanlator data for the library history UI.
  class Fetch
    def initialize(user)
      @user = user
    end

    def call
      @user.readings.includes(
        fiction: [:cover_attachment, { scanlators: :avatar_attachment }]
      ).order(updated_at: :desc)
    end
  end
end
