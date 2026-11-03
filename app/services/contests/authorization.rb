# frozen_string_literal: true

module Contests
  # Access checks for contest entry moderation and withdrawal.
  class Authorization
    def initialize(user, entry = nil)
      @user = user
      @entry = entry
    end

    def moderate?
      user&.admin?
    end

    def withdraw?
      return false if user.blank? || entry.blank?
      return true if user.admin?
      return true if entry.submitter_id == user.id

      entry.authors.exists?(id: user.id)
    end

    private

    attr_reader :user, :entry
  end
end
