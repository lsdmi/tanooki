# frozen_string_literal: true

class FictionUpdatesPresenter
  include ActionView::Helpers::AssetUrlHelper
  include Rails.application.routes.url_helpers

  UKRAINE_TIME_ZONE = 'Kyiv'

  def initialize
    @fictions = Fiction.all
  end

  def last_three_days_updates
    ukraine_time_now = Time.current.in_time_zone(UKRAINE_TIME_ZONE)
    start_date = 2.days.ago(ukraine_time_now).beginning_of_day
    end_date = ukraine_time_now.end_of_day

    chapters = Chapter.joins(:fiction)
                      .where(fictions: { id: @fictions.pluck(:id) })
                      .where(created_at: start_date..end_date)
                      .order(:created_at)

    grouped_updates = chapters.group_by { |chapter| chapter.created_at.in_time_zone(UKRAINE_TIME_ZONE).to_date }

    grouped_updates.map do |date, day_chapters|
      {
        day: I18n.l(date.in_time_zone(UKRAINE_TIME_ZONE), format: '%A'),
        date: I18n.l(date.in_time_zone(UKRAINE_TIME_ZONE), format: '%d/%m'),
        updates: day_chapters.group_by { |chapter| chapter.fiction.slug }
                             .map do |fiction_slug, fiction_chapters|
          fiction = fiction_chapters.first.fiction
          scanlator = fiction.scanlators.sample
          {
            chapters_count: fiction_chapters.count,
            chapters_created_at: fiction_chapters.min_by(&:created_at).created_at.in_time_zone(UKRAINE_TIME_ZONE).strftime('%H:%M'),
            fiction_cover: fiction.cover,
            fiction_genres: fiction.genres.sample(3).pluck(:name),
            fiction_slug: fiction_slug,
            fiction_title: fiction.title,
            fiction_views: fiction.views,
            latest_chapter_slug: fiction_chapters.last.slug,
            latest_chapter_title: fiction_chapters.last.display_title_no_volume,
            scanlator_avatar: scanlator.avatar,
            scanlator_bank_url: scanlator.bank_url.presence,
            scanlator_slug: scanlator.slug,
            scanlator_title: scanlator.title
          }
        end.sort_by { |update| update[:added_at] }
      }
    end
  end
end
