# frozen_string_literal: true

module Contests
  # Guest-facing contest shows are allowlisted. Admins see every show.
  # LISTED opens all visible shows + submit surfaces (no public /contests hub).
  module PublicAccess
    LISTED = false
    PUBLIC_SHOW_SLUGS = %w[i-konkurs-ranobe ii-konkurs-ranobe].freeze

    module_function

    def listed?
      LISTED
    end

    def public_show_slugs
      PUBLIC_SHOW_SLUGS
    end

    def visible?(user)
      listed? || user&.admin?
    end

    def show_visible?(contest, user)
      visible?(user) || (contest.present? && public_show_slugs.include?(contest.slug))
    end

    def surfaces_visible?(user)
      visible?(user) || public_show_slugs.any?
    end

    # Contests that may appear in guest-facing badges/tags/sitemap shows.
    def discoverable_contests
      return Contest.visible if listed?

      Contest.visible.where(slug: public_show_slugs)
    end
  end
end
