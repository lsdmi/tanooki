# frozen_string_literal: true

module DashboardHelper
  def crud_permissions?(object, user)
    fictions = user.fictions.includes(:chapters)
    chapter_ids = fictions.flat_map { |fiction| fiction.chapters.pluck(:id) }

    if object.is_a?(Fiction)
      fictions.include?(object)
    elsif object.is_a?(Chapter)
      chapter_ids.include?(object.id)
    end
  end
end
