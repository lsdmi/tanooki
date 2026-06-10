# frozen_string_literal: true

module Scanlators
  # Who may manage scanlator team membership on create/edit forms.
  class Authorization
    def initialize(user, scanlator)
      @user = user
      @scanlator = scanlator
    end

    def manage_members?
      return false unless user
      return true if user.admin? || scanlator.new_record?

      scanlator.users.exists?(id: user.id)
    end

    private

    attr_reader :user, :scanlator
  end
end
