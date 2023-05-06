# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  def punch(string)
    sentence_end = string.index(/[.?!]/)
    string[0..sentence_end]
  end

  def meta_title
    return "#{params[:search].to_sentence} | Бака" if request.path == search_index_path

    @publication&.title || 'Бака - Новини Аніме та Манґа'
  end

  def meta_description
    return punch(@publication.description.to_plain_text) if @publication&.description.present?

    'Бака - провідний портал аніме та манґа новин в Україні: новини, огляди, статті, інтерв\'ю та інше.'
  end

  def meta_image
    result_cover = case request.path
                   when root_path
                     @highlights.first&.cover
                   when search_index_path
                     @results.first&.cover
                   else
                     publication_cover
                   end

    url_for(result_cover || asset_path('login.jpg'))
  end

  def meta_type
    case request.path
    when root_path, search_index_path
      'website'
    else
      'article'
    end
  end

  def publication_cover
    @publication&.persisted? ? @publication.cover : nil
  end

  def requires_tinymce?
    path_strings = ['admin/tales', 'dashboard', 'publications']
    return true if path_strings.any? { |str| request.path.include?(str) }
  end
end
