# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

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
      'chapters', 'dashboard', 'fictions', 'publications'
    ]
    return true if path_strings.any? { |str| request.path.include?(str) }
  end
end
