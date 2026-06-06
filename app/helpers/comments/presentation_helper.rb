# frozen_string_literal: true

module Comments
  # Commentable links, empty-state copy, and read-status hints for comment UI.
  module PresentationHelper
    def application_record_child(object)
      object.class.superclass == ApplicationRecord ? object.class : object.class.superclass
    end

    def no_comments_prompt
      case params[:controller].to_sym
      when :chapters
        'Наразі відгуки до цього розділу відсутні!'
      when :fictions
        'Наразі відгуки до цього твору відсутні!'
      else
        'Наразі відгуки до цього допису відсутні!'
      end
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

    def show_comment_status?
      current_user.latest_read_comment_id != latest_comments.first&.id
    end
  end
end
