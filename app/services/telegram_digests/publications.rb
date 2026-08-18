# frozen_string_literal: true

module TelegramDigests
  # Friday CI digest: weekly publications → @bakaInUa.
  class Publications
    # Telegram caps messages at 4096 characters; cap how many publications we list.
    WEEKLY_PUBLICATIONS_LIMIT = 5

    def self.call
      new.call
    end

    def call
      return unless Rails.env.production?
      return unless Publication.weekly.any?

      Sender.call(text_message)
    end

    def text_message
      ActionController::Base.helpers.sanitize(
        "📝 <i><b>Збірка останніх дописів на <a href=\"#{index_path}\">сайті</a></b> \n\n" \
        "#{recent_publications} \n\n" \
        "✨ <b>Підтримайте нас на <a href=\"https://www.buymeacoffee.com/bakainua\">buymeacoffee</a>!</b></i> ✨ \n\n "
      )
    end

    private

    def index_path
      Rails.application.routes.url_helpers.tales_url(host: ApplicationHelper::PRODUCTION_URL)
    end

    def recent_publications
      Publication.weekly.limit(WEEKLY_PUBLICATIONS_LIMIT).map do |publication|
        "📰 <b><a href=\"#{route(publication)}\">#{publication.title}</a></b>"
      end.join("\n\n")
    end

    def route(publication)
      Rails.application.routes.url_helpers.tale_url(publication, host: ApplicationHelper::PRODUCTION_URL)
    end
  end
end
