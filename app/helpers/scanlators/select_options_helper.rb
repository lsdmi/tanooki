# frozen_string_literal: true

module Scanlators
  # Title/id pairs for scanlator multi-selects (admin sees all teams; others see their own).
  module SelectOptionsHelper
    def scanlator_select_options(user)
      scanlators = user.admin? ? Scanlator.all : user.scanlators
      scanlators.order(:title).pluck(:title, :id)
    end

    def can_manage_scanlator_members?(user, scanlator:)
      return false unless user
      return true if user.admin? || scanlator.new_record?

      scanlator.users.exists?(id: user.id)
    end
  end
end
