# frozen_string_literal: true

module CommentsHelper
  def fictions?
    @commentable.instance_of?(Fiction) || @commentable.instance_of?(Chapter)
  end

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
      'Наразі відгуки до цієї звістки відсутні!'
    end
  end

  def comments_green?
    %i[chapters fictions].include? params[:controller].to_sym
  end

  def comments_dark_mode?
    params[:controller].to_sym == :chapters ||
      (params[:controller].to_sym == :comments &&
        (request.referer&.include?('chapters') || request.referer&.include?('tales'))
      ) ||
      params[:controller].to_sym == :tales
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

  def commentable_type(commentable)
    case commentable
    when Chapter, Fiction
      'роману'
    when YoutubeVideo
      'відео'
    when Publication
      'блогу'
    end
  end

  def comment_alt(commentable)
    case commentable
    when Chapter, Fiction, Tale
      commentable.cover.blob.filename.to_s
    else
      commentable.title
    end
  end

  def comment_cover(commentable)
    case commentable
    when Chapter, Fiction, Tale then commentable.cover
    else commentable.thumbnail
    end
  end

  def comment_class(commentable)
    case commentable
    when Chapter, Fiction then 'Ранобе'
    when Tale then 'Блог'
    else 'Відео'
    end
  end

  def klass_styles(commentable)
    case commentable
    when Chapter, Fiction then 'bg-emerald-100 text-emerald-800'
    when YoutubeVideo then 'bg-rose-100 text-rose-800'
    when Publication then 'bg-sky-100 text-sky-800'
    end
  end

  def commentable_title(commentable)
    commentable.is_a?(Chapter) ? commentable.fiction_title : commentable.title
  end

  def show_comment_status?
    current_user.latest_read_comment_id != latest_comments.first&.id
  end
end
