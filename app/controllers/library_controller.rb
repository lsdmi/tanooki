# frozen_string_literal: true

class LibraryController < ApplicationController
  before_action :authenticate_user!

  def index
    @history = current_user.readings.includes(
      [{ fiction: { cover_attachment: :blob } }, { fiction: :genres }, :chapter]
    ).order(updated_at: :desc)

    return if @history.any?

    @history_stats = history_stats
    @popular_fictions = popular_fictions
  end

  private

  def history_stats
    {
      total_chapters: Chapter.all.size,
      total_fictions: Fiction.all.size,
      total_views: Chapter.pluck(:views).sum
    }
  end

  def popular_fictions
    Rails.cache.fetch('popular_fictions_library', expires_in: 12.hours) do
      Fiction.includes([{ cover_attachment: :blob }]).order(views: :desc).limit(2)
    end
  end
end
