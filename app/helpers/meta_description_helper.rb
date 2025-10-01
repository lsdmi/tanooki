# frozen_string_literal: true

module MetaDescriptionHelper
  DEFAULT_DESCRIPTION = 'Бака - винятковий портал, де зібрані усі новини, блоги, відео по аніме, ' \
                        'манзі, культурі Сходу, а також перекладається ранобе українською мовою.'

  def meta_description
    if description_object.present?
      object_description
    elsif title_object.present?
      scanlator_description
    elsif consts_paths?
      I18n.t("meta.description.#{controller_name}.#{action_name}")
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

  def consts_paths?
    request.path == fictions_path ||
      request.path == youtube_videos_path ||
      request.path == alphabetical_fictions_path ||
      request.path == calendar_fictions_path ||
      request.path == tales_path ||
      request.path == rules_path ||
      request.path == translation_requests_path
  end

  def description_object
    @description_object ||= [@publication, @fiction, @chapter&.fiction, @youtube_video,
                             @bookshelf].compact.find(&:persisted?)
  end

  def fiction_description
    if @fiction.scanlators.any?
      "Читати ранобе \"#{@fiction.title}\" у перекладі команди \"#{@fiction.scanlators.map(&:title).to_sentence}\"."
    else
      "Читати ранобе \"#{@fiction.title}\" за авторства \"#{@fiction.author}\"."
    end
  end

  def object_description
    return publication_description if publication_persisted?
    return fiction_description if fiction_persisted?
    return chapter_description if chapter_persisted?
    return bookshelf_description if bookshelf_persisted?

    @youtube_video&.description
  end

  def publication_persisted?
    @publication&.persisted?
  end

  def fiction_persisted?
    @fiction&.persisted?
  end

  def chapter_persisted?
    @chapter&.persisted?
  end

  def bookshelf_persisted?
    @bookshelf&.persisted?
  end

  def bookshelf_description
    fiction_titles = @bookshelf.fictions.limit(3).pluck(:title).to_sentence
    "#{@bookshelf.title} від #{@bookshelf.user_name}. #{@bookshelf.description}." \
      "Зокрема #{fiction_titles}#{@bookshelf.fictions.count > 3 ? ' та інш твори' : ''}."
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
