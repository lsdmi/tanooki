# frozen_string_literal: true

module ScanlatorsHelper
  def scanlators_list(user)
    scanlators = user.admin? ? Scanlator.all : user.scanlators
    scanlators.order(:title).pluck(:title, :id)
  end
end
