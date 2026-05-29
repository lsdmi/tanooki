# frozen_string_literal: true

module Youtube
  # Production digest: top videos of the week posted to the @bakaInUa Telegram channel.
  class TelegramJob < ApplicationJob
    include TelegramApiJob

    queue_as :default

    def perform
      return unless Rails.env.production?

      send_telegram_message
    end

    private

    def index_path
      Rails.application.routes.url_helpers.youtube_videos_url(host: ApplicationHelper::PRODUCTION_URL)
    end

    def medal_icon(index)
      case index
      when 0
        '🥇'
      when 1
        '🥈'
      when 2
        '🥉'
      end
    end

    def send_telegram_message
      TelegramBot.client.api.send_message(chat_id: '@bakaInUa', text: text_message, parse_mode: 'HTML')
    end

    def text_message
      ActionController::Base.helpers.sanitize(
        "🌟 <i>Найпопулярніші відео тижня на <b><a href=\"#{index_path}\">Баці</a></b></i> 🌟 \n\n" \
        "#{top_three.each_with_index.map do |video, index|
             "#{medal_icon(index)} <b><a href=\"#{video_path(video)}\">#{video.title}</a></b> #{medal_icon(index)}"
           end.join("\n\n")} \n\n" \
        "🎬 <i>Насолоджуйтеся світом японської анімації на нашому сайті!</i> 🎬 \n\n " \
        '<i><b>#щотижневий_ютуб</b></i>'
      )
    end

    def top_three
      YoutubeVideo.last_week.order(views: :desc).limit(3)
    end

    def video_path(video)
      Rails.application.routes.url_helpers.youtube_video_url(video, host: ApplicationHelper::PRODUCTION_URL)
    end
  end
end
