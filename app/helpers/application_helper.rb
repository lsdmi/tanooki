# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  PRODUCTION_URL = 'https://baka.in.ua'

  def punch(string)
    sentences = string.scan(/.*?[.?!](?=\s|\z)/)
    result = ''

    sentences.each do |sentence|
      result.length <= 20 ? result += sentence : break
    end

    result.presence || string
  end

  def chapters_show_page?
    controller_name.to_sym == :chapters && action_name.to_sym == :show
  end

  def chapters_show_referer?
    request.referer&.include?('chapters') && controller_name.to_sym == :comments
  end

  def requires_font?
    (controller_name.to_sym == :tales && action_name.to_sym == :show) ||
      (controller_name.to_sym == :chapters && action_name.to_sym == :show)
  end

  def requires_tinymce?
    (controller_name == 'publications' && %w[new edit create update].include?(action_name)) ||
      (controller_name == 'chapters' && %w[new edit create update].include?(action_name))
  end

  def requires_sweetalert?
    controller_name.in?(%w[studio readings])
  end

  def pagy_nav_with_turbo_frame(pagy, frame_id = 'tab-content')
    pagy_nav(pagy).gsub('<a ', "<a data-turbo-frame=\"#{frame_id}\" data-turbo-stream=\"true\" ")
  end
end
