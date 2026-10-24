# frozen_string_literal: true

module ContentFilters
  # Builds a Preference for this request. A signed-in account wins over the guest cookie.
  class Resolver
    COOKIE_KEY = :content_filter
    GUEST_HIDE_EIGHTEEN = 'no18'

    def self.call(user:, cookies:)
      return for_account(user) if user

      for_guest(cookies)
    end

    def self.for_account(user)
      rows = User.where(id: user.id)
                 .left_outer_joins(:content_filter, :hidden_packages)
                 .pluck('user_content_filters.max_content_rating', 'user_hidden_packages.package_key')
      return Preference.open if rows.empty?

      keys = rows.filter_map(&:last).uniq.select { |key| Packages.key?(key) }
      Preference.new(max_rating: rows.first.first, package_keys: keys, hidden_genre_ids: Packages.genre_ids_for(keys))
    end
    private_class_method :for_account

    def self.for_guest(cookies)
      return Preference.open unless cookies&.signed&.[](COOKIE_KEY) == GUEST_HIDE_EIGHTEEN

      Preference.new(max_rating: 16, hidden_genre_ids: [].freeze)
    end
    private_class_method :for_guest
  end
end
