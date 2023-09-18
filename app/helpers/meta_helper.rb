# frozen_string_literal: true

module MetaHelper
  RANOBE_SEO_DESCRIPTION = 'Найбільша колекція новел та фанфіків українською мовою. ' \
                           'Захоплюючі історії, герої та світи. ' \
                           'Щоденні оновлення на нашому сайті!'

  YOUTUBE_SEO_DESCRIPTION = 'Захоплюючі відео від талановитих українських ютуберів про аніме, манґу та культуру Сходу.'

  def meta_cover
    if @publication&.persisted?
      @publication.cover
    elsif @fiction&.persisted?
      @fiction.cover
    elsif @chapter&.persisted?
      @chapter.fiction.cover
    elsif @youtube_video&.persisted?
      @youtube_video.thumbnail
    end
  end

  def meta_description
    if publication_description_present?
      punch(publication_description)
    elsif fiction_description_present?
      fiction_description
    elsif chapter_content_present?
      chapter_description
    elsif request_path_is_fictions_path?
      RANOBE_SEO_DESCRIPTION
    elsif youtube_video_description?
      @youtube_video.description
    elsif request.path == youtube_videos_path
      YOUTUBE_SEO_DESCRIPTION
    else
      default_description
    end
  end

  def meta_image
    result_cover = case request.path
                   when root_path then highlights_cover
                   when fictions_path then fictions_cover
                   when search_index_path then results_cover
                   when youtube_videos_path then youtube_video_cover
                   else meta_cover
                   end

    url_for(result_cover || asset_path('login.jpg'))
  end

  def meta_title
    return "#{params[:search].to_sentence} | Бака" if request.path == search_index_path
    return 'Бака - Ранобе та Фанфіки' if request.path == fictions_path
    return chapter_title if @chapter.present? && @chapter.persisted?
    return @youtube_video.title if @youtube_video&.persisted?
    return 'Український аніме-ютуб: відео на Бака' if request.path == youtube_videos_path

    [@publication, @fiction].compact.map(&:title).first || 'Бака - Новини Аніме та Манґа'
  end

  def meta_type
    case request.path
    when root_path, search_index_path, fictions_path, youtube_videos_path
      'website'
    else
      'article'
    end
  end

  private

  def chapter_title
    "#{@chapter.fiction_title} | #{@chapter.display_title}"
  end

  def chapter_description
    if @chapter.translator.present?
      "Читати #{@chapter.display_title} \"#{@chapter.fiction_title}\" у перекладі команди \"#{@chapter.translator}\"."
    else
      "Читати #{@chapter.display_title} \"#{@chapter.fiction_title}\" за авторства #{@chapter.author}."
    end
  end

  def chapter_content_present?
    @chapter&.content.present?
  end

  def default_description
    'Бака - провідний портал аніме та манґа новин в Україні: новини, огляди, статті, інтерв\'ю та інше.'
  end

  def fictions_cover
    params[:action] == 'index' ? @latest_updates&.first&.cover : meta_cover
  end

  def fiction_description
    if @fiction.translator?
      "Читати ранобе \"#{@fiction.title}\" у перекладі команди \"#{@fiction.translator}\"."
    else
      "Читати ранобе \"#{@fiction.title}\" за авторства \"#{@fiction.author}\"."
    end
  end

  def youtube_video_cover
    @highlights.first&.thumbnail
  end

  def youtube_video_description?
    @youtube_video&.description.present?
  end

  def fiction_description_present?
    @fiction&.description.present?
  end

  def highlights_cover
    @highlights.first&.cover
  end

  def publication_description
    @publication.description.to_plain_text
  end

  def publication_description_present?
    @publication&.description.present?
  end

  def request_path_is_fictions_path?
    request.path == fictions_path
  end

  def results_cover
    @results&.first&.cover
  end
end
