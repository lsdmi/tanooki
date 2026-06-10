# frozen_string_literal: true

module Comments
  # Commentable links, empty-state copy, and STI class resolution for comment UI.
  class Presentation
    include Rails.application.routes.url_helpers

    EMPTY_STATE_BY_CONTROLLER = {
      chapters: 'Наразі відгуки до цього розділу відсутні!',
      fictions: 'Наразі відгуки до цього твору відсутні!'
    }.freeze
    DEFAULT_EMPTY_STATE = 'Наразі відгуки до цього допису відсутні!'

    def self.application_record_child(object)
      object.class.superclass == ApplicationRecord ? object.class : object.class.superclass
    end

    def self.empty_state_for(controller_name)
      EMPTY_STATE_BY_CONTROLLER[controller_name.to_sym] || DEFAULT_EMPTY_STATE
    end

    def comment_url(comment)
      case comment.commentable
      when Chapter
        chapter_path(comment.commentable)
      when YoutubeVideo
        youtube_video_path(comment.commentable)
      when Fiction
        fiction_path(comment.commentable)
      when Publication
        tale_path(comment.commentable)
      end
    end

    def commentable_title(commentable)
      case commentable
      when Chapter
        "#{commentable.fiction_title} · #{commentable.display_title_no_volume}"
      else
        commentable.title
      end
    end
  end
end
