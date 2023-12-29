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
end
