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

  def requires_tinymce?
    path_strings = [
      'admin/chapters', 'admin/fictions', 'admin/tales',
      'chapters', 'fictions', 'publications'
    ]
    return true if path_strings.any? { |str| request.path.include?(str) }
  end

  def requires_sweetalert?
    return true if request.path == library_path
  end
end
