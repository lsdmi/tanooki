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
    [
      'admin/chapters', 'admin/fictions', 'admin/tales', 'chapters', 'fictions', 'publications'
    ].any? { |str| request.path.include?(str) }
  end

  def requires_sweetalert?
    request.path == library_path
  end
end
