# frozen_string_literal: true

class FictionsTelegramJob < ApplicationJob
  queue_as :default

  def perform
    @api_call_executed ||= false
    @@mutex ||= Mutex.new

    @@mutex.synchronize do
      unless @api_call_executed
        return unless Rails.env.production?
        return unless Fiction.recent.any?

        TelegramBot.client.api.send_message(chat_id: '@bakaInUa', text: text_message, parse_mode: 'HTML')

        @api_call_executed = true
      end
    end
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
      fiction_details = "📖 <b><a href=\"#{route(fiction)}\">#{fiction.title}</a></b> \n\n"
      fiction_description = "<i>#{fiction.description[0..100]}...</i> \n\n"
      genre_details = fiction.genres.map { |genre| "<i>##{formatted_genres(genre)}</i>" }.join(', ')
      "#{fiction_details}#{fiction_description}#{genre_details}"
    end.join("\n\n")
  end

  def route(fiction)
    Rails.application.routes.url_helpers.fiction_url(fiction, host: ApplicationHelper::PRODUCTION_URL)
  end

  def text_message
    ActionController::Base.helpers.sanitize(
      "📚 <i>Нові веб-романи на <b><a href=\"#{index_path}\">Баці</a></b></i> 📚 \n\n" \
      "#{recent_fictions} \n\n" \
      "✨ <i>Підтримайте нас на <b><a href=\"https://www.buymeacoffee.com/bakainua\">buymeacoffee</a></b>!</i> ✨ \n\n "
    )
  end
end
