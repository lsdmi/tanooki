# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  def meta_title
    return "#{params[:search].to_sentence} | Бака" if request.path == search_index_path

    @publication&.title || 'Бака - Новини Аніме та Манґа'
  end

  def meta_description
    @publication&.description&.to_plain_text&.truncate(125) ||
      'Бака - провідний портал аніме та манґа новин в Україні: новини, огляди, статті, інтерв\'ю та інше.'
  end

  def requires_tinymce?
    %w[admin/tales].any? { |string| controller_path.include? string }
  end
end
