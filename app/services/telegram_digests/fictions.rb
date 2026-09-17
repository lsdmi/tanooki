# frozen_string_literal: true

module TelegramDigests
  # Thursday CI digest: fictions created since last Thursday → @bakaInUa.
  class Fictions
    # Telegram caps messages at 4096 characters; cap how many fictions we list.
    DIGEST_LIMIT = 5

    def self.call
      new.call
    end

    def call
      return unless Rails.env.production?
      return unless Fiction.for_thursday_digest.any?

      Sender.call(text_message)
    end

    def text_message
      ActionController::Base.helpers.sanitize(
        "📚 <i><b>Нові веб-романи на <a href=\"#{index_path}\">Баці</a></b> 📚 \n\n" \
        "#{digest_fictions} \n\n" \
        "✨ <b>Підтримайте нас на <a href=\"https://www.buymeacoffee.com/bakainua\">buymeacoffee</a>!</b></i> ✨ \n\n "
      )
    end

    private

    def formatted_genres(genre)
      genre.name.downcase.gsub(/[\s,!-]+/, '_').gsub(/_$/, '')
    end

    def index_path
      Rails.application.routes.url_helpers.fictions_url(host: ApplicationHelper::PRODUCTION_URL)
    end

    def digest_fictions
      Fiction.for_thursday_digest.limit(DIGEST_LIMIT).map do |fiction|
        fiction_details = "📖 <b><a href=\"#{route(fiction)}\">#{fiction.title}</a></b>"
        genre_details = fiction.genres.first(5).map { |genre| "##{formatted_genres(genre)}" }.join(', ')
        genre_details.present? ? "#{fiction_details} #{genre_details}" : fiction_details
      end.join("\n\n")
    end

    def route(fiction)
      Rails.application.routes.url_helpers.fiction_url(fiction, host: ApplicationHelper::PRODUCTION_URL)
    end
  end
end
