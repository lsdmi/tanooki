# frozen_string_literal: true

# Wednesday digest: stats for this week + highlights from last calendar week (Europe/Kiev).
class WeeklyStatsTelegramJob < ApplicationJob
  include TelegramApiJob

  queue_as :default

  BUYMECOFFEE_URL = 'https://www.buymeacoffee.com/bakainua'

  def perform
    return unless Rails.env.production?

    send_weekly_digest_to_telegram
  end

  private

  def send_weekly_digest_to_telegram
    TelegramBot.client.api.send_message(chat_id: '@bakaInUa', text: text_message, parse_mode: 'HTML')
  end

  # --- message assembly

  def text_message
    body = [digest_intro, digest_sections, digest_footer].compact_blank.join("\n\n")
    ActionController::Base.helpers.sanitize("<i>#{body}</i>")
  end

  def digest_intro
    "<b>👋 Тиждень на <a href=\"#{fictions_index_url}\">Баці</a></b> - " \
      'нові розділи, топи, що залетіли, і одна серія - раптом ваша!'
  end

  def digest_sections
    [
      chapters_this_week_section,
      top_chapter_section,
      top_fiction_readers_section,
      random_active_fiction_section
    ].compact_blank.join("\n\n")
  end

  def digest_footer
    '☕ Підтримайте кавою на ' \
      "<b><a href=\"#{BUYMECOFFEE_URL}\">buymeacoffee</a> #дайджест</b>"
  end

  def chapters_this_week_section
    n = chapters_public_in(this_week_range).count
    "📚 цього тижня на сайті з'явилося <b>#{n}</b> нових розділів"
  end

  def top_chapter_section
    chapter = top_chapter_last_week
    return if chapter.blank?

    "📚 <b>топ-розділ тижня</b> - #{chapter_title_link(chapter)}"
  end

  def top_fiction_readers_section
    fiction = top_fiction_by_reading_activity_last_week
    return if fiction.blank?

    "📚 <b>ранобе тижня</b> - #{fiction_title_link(fiction)}"
  end

  def random_active_fiction_section
    fiction = random_fiction_with_new_chapter_last_week
    return if fiction.blank?

    "📚 <b>варте уваги - </b>#{fiction_title_link(fiction)}"
  end

  # --- HTML snippets

  def chapter_title_link(chapter)
    label = "#{ERB::Util.html_escape(chapter.display_title)} — #{ERB::Util.html_escape(chapter.fiction_title)}"
    link_line(label, production_url(chapter))
  end

  def fiction_title_link(fiction)
    link_line(ERB::Util.html_escape(fiction.title), production_url(fiction))
  end

  def link_line(label, href)
    "<b><a href=\"#{href}\">#{label}</a></b>"
  end

  # --- queries

  def chapters_public_in(range)
    Chapter.released.where("#{Chapter::PUBLIC_TIME_SQL} BETWEEN ? AND ?", range.begin, range.end)
  end

  def top_chapter_last_week
    chapters_public_in(last_week_range).order(views: :desc, id: :asc).first
  end

  def top_fiction_by_reading_activity_last_week
    t = last_week_range
    counts = ReadingProgress.where(updated_at: t.begin..t.end).group(:fiction_id).count
    return nil if counts.empty?

    fiction_id = counts.max_by { |fid, cnt| [cnt, -fid] }&.first
    Fiction.find_by(id: fiction_id)
  end

  def random_fiction_with_new_chapter_last_week
    Fiction.joins(:chapters).merge(chapters_public_in(last_week_range))
           .distinct.order(Arel.sql('RAND()')).first
  end

  def this_week_range
    Time.zone.now.all_week
  end

  def last_week_range
    1.week.ago.all_week
  end

  # --- URLs

  def fictions_index_url
    routes.fictions_url(host: ApplicationHelper::PRODUCTION_URL)
  end

  def production_url(record)
    routes.polymorphic_url(record, host: production_host, protocol: 'https')
  end

  def production_host
    URI(ApplicationHelper::PRODUCTION_URL).host
  end

  def routes
    Rails.application.routes.url_helpers
  end
end
