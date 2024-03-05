# frozen_string_literal: true

class PublicationsTelegramJob < ApplicationJob
  queue_as :default

  def perform
    return unless Rails.env.production?
    return unless Publication.recent.any?

    TelegramBot.client.api.send_message(chat_id: '@bakaInUa', text: text_message, parse_mode: 'HTML')
  end

  private

  def formatted_tags(tag)
    tag.name.downcase.gsub(/[\s,!\-]+/, '_').gsub(/_$/, '')
  end

  def index_path
    Rails.application.routes.url_helpers.tales_url(host: ApplicationHelper::PRODUCTION_URL)
  end

  def recent_publications
    Publication.recent.map do |publication|
      publication_details = "🏷️ <b><a href=\"#{route(publication)}\">#{publication.title}</a></b> \n\n"
      publication_description = "<i>#{publication.description.to_plain_text[0..120]}...</i> \n\n"
      tag_details = publication.tags.map { |tag| "<i>##{formatted_tags(tag)}</i>" }.join(', ')
      "#{publication_details}#{publication_description}#{tag_details}"
    end.join("\n\n")
  end

  def route(publication)
    Rails.application.routes.url_helpers.tale_url(publication, host: ApplicationHelper::PRODUCTION_URL)
  end

  def text_message
    ActionController::Base.helpers.sanitize(
      "📝 <i>Збірка останніх дописів на нашому <b><a href=\"#{index_path}\">сайті</a></b></i> 📝 \n\n" \
      "#{recent_publications} \n\n" \
      "🎉 <i>Підтримуйте нас на <b><a href=\"https://www.buymeacoffee.com/bakainua\">buymeacoffee</a></b>!</i> 🎉 \n\n"
    )
  end
end
