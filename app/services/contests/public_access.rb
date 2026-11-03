# frozen_string_literal: true

module Contests
  # Gates hub, show, submit, nav, tags, rules links, and sitemap until launch.
  # Flip LISTED to true when contests go public; admins always see surfaces.
  module PublicAccess
    LISTED = false

    module_function

    def listed?
      LISTED
    end

    def visible?(user)
      listed? || user&.admin?
    end
  end
end
