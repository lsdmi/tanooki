# frozen_string_literal: true

module Studio
  # Paragraph error reports live under Studio → Сповіщення, but only for admins or
  # people who already have a team and works (not for pure readers).
  class ParagraphReportsAccess
    def self.allowed?(user)
      return false unless user
      return true if user.admin?

      user.scanlators.exists? && user.fictions.exists?
    end
  end
end
