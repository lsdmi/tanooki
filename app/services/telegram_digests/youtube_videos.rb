# frozen_string_literal: true

module TelegramDigests
  # Weekly CI digest: top YouTube videos of the week → @bakaInUa.
  class YoutubeVideos
    def self.call
      new.call
    end

    def call
      return unless Rails.env.production?

      Sender.call(text_message)
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

    private

    def index_path
      Rails.application.routes.url_helpers.youtube_videos_url(host: ApplicationHelper::PRODUCTION_URL)
    end

    def medal_icon(index)
      case index
      when 0 then '🥇'
      when 1 then '🥈'
      when 2 then '🥉'
      end
    end

    def top_three
      YoutubeVideo.last_week.order(views: :desc).limit(3)
    end

    def video_path(video)
      Rails.application.routes.url_helpers.youtube_video_url(video, host: ApplicationHelper::PRODUCTION_URL)
    end
  end
end
