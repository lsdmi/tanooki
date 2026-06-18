# frozen_string_literal: true

module WeeklyDigests
  # Builds the HTML Telegram message for the weekly stats digest.
  class MessageRenderer
    BUYMECOFFEE_URL = 'https://www.buymeacoffee.com/bakainua'

    def initialize(stats: Stats.build, routes: Rails.application.routes.url_helpers)
      @stats = stats
      @routes = routes
    end

    def call
      body = [intro, sections, footer].compact_blank.join("\n\n")
      ActionController::Base.helpers.sanitize("<i>#{body}</i>")
    end

    private

    attr_reader :stats, :routes

    def intro
      "<b>👋 Тиждень на <a href=\"#{fictions_index_url}\">Баці</a></b> - " \
        'нові розділи, топи, що залетіли, і одна серія - раптом ваша!'
    end

    def sections
      [
        chapters_this_week_section,
        top_chapter_section,
        top_fiction_readers_section,
        random_active_fiction_section
      ].compact_blank.join("\n\n")
    end

    def footer
      '☕ Підтримайте кавою на ' \
        "<b><a href=\"#{BUYMECOFFEE_URL}\">buymeacoffee</a> #дайджест</b>"
    end

    def chapters_this_week_section
      "📚 цього тижня на сайті з'явилося <b>#{stats.chapters_this_week_count}</b> нових розділів"
    end

    def top_chapter_section
      return if stats.top_chapter.blank?

      "📚 <b>топ-розділ тижня</b> - #{chapter_title_link(stats.top_chapter)}"
    end

    def top_fiction_readers_section
      return if stats.top_fiction.blank?

      "📚 <b>ранобе тижня</b> - #{fiction_title_link(stats.top_fiction)}"
    end

    def random_active_fiction_section
      return if stats.featured_fiction.blank?

      "📚 <b>варте уваги - </b>#{fiction_title_link(stats.featured_fiction)}"
    end

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

    def fictions_index_url
      routes.fictions_url(host: ApplicationHelper::PRODUCTION_URL)
    end

    def production_url(record)
      routes.polymorphic_url(record, host: production_host, protocol: 'https')
    end

    def production_host
      URI(ApplicationHelper::PRODUCTION_URL).host
    end
  end
end
