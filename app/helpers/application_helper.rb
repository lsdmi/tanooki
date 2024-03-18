# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  PRODUCTION_URL = 'https://baka.in.ua'

  def navbar_style(tag)
    case tag
    when 'Блоги' then 'text-sky-600 hover:text-sky-700 hover:border-sky-700'
    when 'Відео' then 'text-rose-600 hover:text-rose-700 hover:border-rose-700'
    else 'text-gray-900 hover:text-gray-600 hover:border-gray-700'
    end
  end

  def punch(string)
    sentences = string.scan(/.*?[.?!](?=\s|\z)/)
    result = ''

    sentences.each do |sentence|
      result.length <= 20 ? result += sentence : break
    end

    result.presence || string
  end

  def requires_font?
    (controller_name.to_sym == :tales && action_name.to_sym == :show) ||
      (controller_name.to_sym == :chapters && action_name.to_sym == :show)
  end

  def requires_tinymce?
    [
      'admin/chapters', 'admin/fictions', 'admin/tales', 'chapters', 'fictions', 'publications'
    ].any? { |str| request.path.include?(str) }
  end

  def requires_sweetalert?
    request.path.in? [blogs_path, library_path, readings_path, scanlators_path]
  end
end
