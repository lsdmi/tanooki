# frozen_string_literal: true

module Scanlators
  # Title/id pairs for scanlator multi-selects (admin sees all teams; others see their own).
  module SelectOptionsHelper
    def scanlator_select_options(user)
      scanlators = user.admin? ? Scanlator.all : user.scanlators
      scanlators.order(:title).pluck(:title, :id)
    end

    def can_manage_scanlator_members?(user, scanlator:)
      Scanlators::Authorization.new(user, scanlator).manage_members?
    end
  end
end
