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
    (request.path.in? [blogs_path, library_path, readings_path, scanlators_path, admin_tales_path]) ||
      (controller_name == 'readings')
  end

  def theme_toggler?
    (controller_name == 'tales' && action_name == 'show') ||
      (controller_name == 'chapters' && action_name == 'show') ||
      (controller_name == 'scanlators' && action_name == 'show')
  end
end
