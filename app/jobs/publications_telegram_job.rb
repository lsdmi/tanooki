# frozen_string_literal: true

class PublicationsTelegramJob < ApplicationJob
  queue_as :default

  def perform
    return unless Rails.env.production?
    return unless Publication.weekly.any?

    TelegramBot.client.api.send_message(chat_id: '@bakaInUa', text: text_message, parse_mode: 'HTML')
  end

  private

  def index_path
    Rails.application.routes.url_helpers.tales_url(host: ApplicationHelper::PRODUCTION_URL)
  end

  def recent_publications
    Publication.weekly.map do |publication|
      "📰 <b><a href=\"#{route(publication)}\">#{publication.title}</a></b>"
    end.join("\n\n")
  end

  def route(publication)
    Rails.application.routes.url_helpers.tale_url(publication, host: ApplicationHelper::PRODUCTION_URL)
  end

  def text_message
    ActionController::Base.helpers.sanitize(
      "📝 <i><b>Збірка останніх дописів на <a href=\"#{index_path}\">сайті</a></b> \n\n" \
      "#{recent_publications} \n\n" \
      "✨ <b>Підтримайте нас на <a href=\"https://www.buymeacoffee.com/bakainua\">buymeacoffee</a>!</b></i> ✨ \n\n "
    )
  end
end
