# frozen_string_literal: true

module MetaHelper
  def meta_image
    result_cover = case request.path
                   when root_path then highlights_cover
                   when fictions_path then fictions_cover
                   when search_index_path then results_cover
                   when youtube_videos_path then youtube_video_cover
                   else meta_cover
                   end

    url_for(result_cover || asset_path('login.jpeg'))
  end

  def meta_title
    return "#{params[:search].to_sentence} | Бака" if request.path == search_index_path
    return 'Бака - Ранобе та Фанфіки' if request.path == fictions_path
    return chapter_title if @chapter.present? && @chapter.persisted?
    return @youtube_video.title if @youtube_video&.persisted?
    return 'Український аніме-ютуб: відео на Бака' if request.path == youtube_videos_path
    return "#{@scanlator.title} | Переклади Ранобе | Бака" if @scanlator.present? && @scanlator.persisted?

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

  def fictions_cover
    params[:action] == 'index' ? @latest_updates&.first&.cover : meta_cover
  end

  def youtube_video_cover
    @highlights.first&.thumbnail
  end

  def highlights_cover
    @highlights.first&.cover
  end

  def results_cover
    @results&.first&.cover
  end
end
