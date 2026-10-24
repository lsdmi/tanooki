# frozen_string_literal: true

module ContentFilters
  # Copies a guest «hide 18+» cookie onto an account that has no rating cap yet, then clears the cookie.
  class AdoptGuestCookie
    def self.call(user:, cookies:)
      return unless user&.persisted?
      return unless cookies&.signed&.[](Resolver::COOKIE_KEY) == Resolver::GUEST_HIDE_EIGHTEEN
      return if UserContentFilter.exists?(user_id: user.id)

      user.create_content_filter!(max_content_rating: 16)
      cookies.delete(Resolver::COOKIE_KEY)
    end
  end
end
