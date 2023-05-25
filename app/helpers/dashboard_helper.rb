# frozen_string_literal: true

module DashboardHelper
  def crud_permissions?(object, user)
    return true if user.admin?

    if object.is_a?(Fiction)
      user.fictions.include?(object)
    elsif object.is_a?(Chapter)
      user.chapters.include?(object)
    end
  end
end
