# frozen_string_literal: true

module MetaHelper
  include MetaDescriptionHelper

  def meta_image
    result_cover = case request.path
                   when root_path then highlights_cover
                   when fictions_path then fictions_cover
                   when search_index_path then results_cover
                   when youtube_videos_path then youtube_video_cover
                   else meta_cover
                   end

    url_for(result_cover || highlights_cover)
  end

  def meta_title
    return search_meta_title if search_index_path?
    return I18n.t("meta.title.#{controller_name}.#{action_name}") if consts_paths?
    return chapter_title if chapter_present?
    return youtube_video_title if youtube_video_present?
    return scanlator_meta_title if scanlator_present?

    default_meta_title
  end

  def meta_type
    case request.path
    when root_path, search_index_path, fictions_path, youtube_videos_path, comments_path, alphabetical_fictions_path
      'website'
    else
      'article'
    end
  end

  private

  def search_index_path?
    request.path == search_index_path
  end

  def search_meta_title
    "#{params[:search].to_sentence} | Бака"
  end

  def chapter_present?
    @chapter.present? && @chapter.persisted?
  end

  def youtube_video_present?
    @youtube_video&.persisted?
  end

  def youtube_video_title
    @youtube_video.title
  end

  def scanlator_present?
    @scanlator.present? && @scanlator.persisted?
  end

  def scanlator_meta_title
    "#{@scanlator.title} | Переклади Ранобе | Бака"
  end

  def default_meta_title
    [@publication, @fiction].compact.map(&:title).first || 'Бака: про аніме українською'
  end

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
    asset_path('psyduck_background.webp')
  end

  def results_cover
    @results&.first&.cover
  end
end
