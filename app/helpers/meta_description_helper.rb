# frozen_string_literal: true

module MetaDescriptionHelper
  DEFAULT_DESCRIPTION = 'Бака - провідний портал аніме та манґа новин в Україні: ' \
                        "новини, огляди, статті, інтерв'ю та інше."

  RANOBE_SEO_DESCRIPTION = 'Найбільша колекція новел та фанфіків українською мовою. ' \
                           'Захоплюючі історії, герої та світи. ' \
                           'Щоденні оновлення на нашому сайті!'

  YOUTUBE_SEO_DESCRIPTION = 'Захоплюючі відео від талановитих українських ютуберів про аніме, манґу та культуру Сходу.'

  def meta_description
    if description_object.present?
      object_description
    elsif title_object.present?
      scanlator_description
    elsif consts_descriptions?
      consts_description
    else
      DEFAULT_DESCRIPTION
    end
  end

  private

  def chapter_description
    if @chapter.scanlators.any?
      "Читати #{@chapter.display_title} \"#{@chapter.fiction_title}\" у перекладі команди " \
        "\"#{@chapter.scanlators.map(&:title).to_sentence}\"."
    else
      "Читати #{@chapter.display_title} \"#{@chapter.fiction_title}\" за авторства #{@chapter.author}."
    end
  end

  def consts_description
    request.path == fictions_path ? RANOBE_SEO_DESCRIPTION : YOUTUBE_SEO_DESCRIPTION
  end

  def consts_descriptions?
    request.path == fictions_path || request.path == youtube_videos_path
  end

  def description_object
    @description_object ||= [@publication, @fiction, @chapter&.fiction, @youtube_video].compact.find(&:persisted?)
  end

  def fiction_description
    if @fiction.scanlators.any?
      "Читати ранобе \"#{@fiction.title}\" у перекладі команди \"#{@fiction.scanlators.map(&:title).to_sentence}\"."
    else
      "Читати ранобе \"#{@fiction.title}\" за авторства \"#{@fiction.author}\"."
    end
  end

  def object_description
    if @publication&.persisted?
      publication_description
    elsif @fiction&.persisted?
      fiction_description
    elsif @chapter&.persisted?
      chapter_description
    else
      @youtube_video&.description
    end
  end

  def publication_description
    punch(@publication.description.to_plain_text)
  end

  def scanlator_description
    "#{@scanlator.title} перекладають ранобе та фанфіки українською " \
      "(#{@scanlator.fictions.map(&:title).to_sentence.truncate(75)}). " \
      'Читайте онлайн на Бака!'
  end

  def title_object
    @title_object ||= [@scanlator].compact.find(&:persisted?)
  end
end
