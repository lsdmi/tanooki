# frozen_string_literal: true

class FictionsTelegramJob < ApplicationJob
  queue_as :default

  def perform
    return unless Rails.env.production?
    return unless Fiction.recent.any?

    TelegramBot.client.api.send_message(chat_id: '@bakaInUa', text: text_message, parse_mode: 'HTML')
  end

  private

  def formatted_genres(genre)
    genre.name.downcase.gsub(/[\s,!\-]+/, '_').gsub(/_$/, '')
  end

  def index_path
    Rails.application.routes.url_helpers.fictions_url(host: ApplicationHelper::PRODUCTION_URL)
  end

  def recent_fictions
    Fiction.recent.map do |fiction|
      fiction_details = "📖 <b><a href=\"#{route(fiction)}\">#{fiction.title}</a></b>"
      genre_details = fiction.genres.first(5).map { |genre| "##{formatted_genres(genre)}" }.join(', ')
      genre_details.present? ? "#{fiction_details} #{genre_details}" : fiction_details
    end.join("\n\n")
  end

  def route(fiction)
    Rails.application.routes.url_helpers.fiction_url(fiction, host: ApplicationHelper::PRODUCTION_URL)
  end

  def text_message
    ActionController::Base.helpers.sanitize(
      "📚 <i><b>Нові веб-романи на <a href=\"#{index_path}\">Баці</a></b> 📚 \n\n" \
      "#{recent_fictions} \n\n" \
      "✨ <b>Підтримайте нас на <a href=\"https://www.buymeacoffee.com/bakainua\">buymeacoffee</a>!</b></i> ✨ \n\n "
    )
  end
end
