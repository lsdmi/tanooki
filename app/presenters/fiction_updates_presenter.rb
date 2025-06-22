# frozen_string_literal: true

class FictionUpdatesPresenter
  UKRAINE_TIME_ZONE = 'Kyiv'
  DATE_FORMAT = '%d/%m'
  DAY_FORMAT = '%A'
  CHAPTERS_LIMIT_DAYS = 3

  def initialize(fictions: Fiction.all)
    @fictions = fictions
  end

  def last_three_days_updates
    chapters = recent_chapters
    group_chapters_by_date(chapters).map do |date, day_chapters|
      {
        day: localized_day(date),
        date: localized_date(date),
        updates: build_updates_for_day(day_chapters)
      }
    end
  end

  private

  def ukraine_time_now
    Time.current.in_time_zone(UKRAINE_TIME_ZONE)
  end

  def recent_chapters
    Chapter.includes(fiction: %i[scanlators genres])
           .where(fictions: { id: @fictions.pluck(:id) })
           .where(created_at: last_days_range)
           .order(:created_at)
  end

  def last_days_range
    start_date = (CHAPTERS_LIMIT_DAYS - 1).days.ago(ukraine_time_now).beginning_of_day
    end_date = ukraine_time_now.end_of_day
    start_date..end_date
  end

  def group_chapters_by_date(chapters)
    chapters.group_by { |chapter| chapter.created_at.in_time_zone(UKRAINE_TIME_ZONE).to_date }
  end

  def localized_day(date)
    I18n.l(date, format: DAY_FORMAT)
  end

  def localized_date(date)
    I18n.l(date, format: DATE_FORMAT)
  end

  def build_updates_for_day(day_chapters)
    day_chapters
      .group_by(&:fiction_slug)
      .map { |fiction_slug, fiction_chapters| build_fiction_update(fiction_slug, fiction_chapters) }
      .sort_by { |update| update[:chapters_created_at] }
  end

  def build_fiction_update(fiction_slug, fiction_chapters)
    fiction = fiction_chapters.first.fiction
    scanlator = fiction.scanlators.sample
    {
      chapters_count: fiction_chapters.count,
      chapters_created_at: min_created_at_formatted(fiction_chapters),
      fiction_genres: fiction.genres.sample(3).pluck(:name),
      fiction_slug: fiction_slug,
      fiction_title: fiction.title,
      scanlator_bank_url: scanlator&.bank_url.presence,
      scanlator_slug: scanlator&.slug,
      scanlator_title: scanlator&.title
    }
  end

  def min_created_at_formatted(fiction_chapters)
    fiction_chapters.min_by(&:created_at).created_at.in_time_zone(UKRAINE_TIME_ZONE).strftime('%H:%M')
  end
end
