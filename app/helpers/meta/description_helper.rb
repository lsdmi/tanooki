# frozen_string_literal: true

module Meta
  # Resolves <meta name="description"> and matching Open Graph / Twitter copy per page.
  module DescriptionHelper
    DEFAULT_DESCRIPTION = 'Бака - винятковий портал, де зібрані усі новини, блоги, відео по аніме, ' \
                          'манзі, культурі Сходу, а також перекладається ранобе українською мовою.'
    STATIC_DESCRIPTION_PATHS = %i[
      fictions_path
      youtube_videos_path
      alphabetical_fictions_path
      calendar_fictions_path
      tales_path
      rules_path
      privacy_path
      translation_requests_path
    ].freeze

    def meta_description
      description_from_record ||
        description_from_genre ||
        description_from_scanlator ||
        description_from_static_path ||
        DEFAULT_DESCRIPTION
    end

    private

    def chapter_description
      return chapter_scanlator_description if chapter.scanlators.any?

      "Читати #{chapter.display_title} \"#{chapter.fiction_title}\" за авторства #{chapter.author}."
    end

    def consts_paths?
      STATIC_DESCRIPTION_PATHS.any? { |path_helper| request.path == public_send(path_helper) }
    end

    def description_object
      [publication, fiction, chapter&.fiction, youtube_video, bookshelf].compact.find(&:persisted?)
    end

    def description_from_record
      object_description if description_object.present?
    end

    def description_from_genre
      genre_meta_description if genre_show_page?
    end

    def description_from_scanlator
      scanlator_description if title_object.present?
    end

    def description_from_static_path
      I18n.t("meta.description.#{controller_name}.#{action_name}") if consts_paths?
    end

    def fiction_description
      if fiction.scanlators.any?
        "Читати ранобе \"#{fiction.title}\" у перекладі команди \"#{fiction.scanlators.map(&:title).to_sentence}\"."
      else
        "Читати ранобе \"#{fiction.title}\" за авторства \"#{fiction.author}\"."
      end
    end

    def object_description
      return publication_description if publication_persisted?
      return fiction_description if fiction_persisted?
      return chapter_description if chapter_persisted?
      return bookshelf_description if bookshelf_persisted?

      youtube_video&.description
    end

    def publication_persisted?
      publication&.persisted?
    end

    def fiction_persisted?
      fiction&.persisted?
    end

    def chapter_persisted?
      chapter&.persisted?
    end

    def bookshelf_persisted?
      bookshelf&.persisted?
    end

    def bookshelf_description
      fiction_titles = bookshelf.fictions.limit(3).pluck(:title).to_sentence
      "#{bookshelf.title} від #{bookshelf.user_name}. #{bookshelf.description}." \
        "Зокрема #{fiction_titles}#{bookshelf.fictions.count > 3 ? ' та інш твори' : ''}."
    end

    def publication_description
      punch(publication.description.to_plain_text)
    end

    def scanlator_description
      "#{scanlator.title} перекладають ранобе та фанфіки українською " \
        "(#{scanlator.fictions.map(&:title).to_sentence.truncate(75)}). " \
        'Читайте онлайн на Бака!'
    end

    def genre_meta_description
      I18n.t('meta.description.genres.show', name: genre.name, count: genre.fictions.count)
    end

    def title_object
      [scanlator].compact.find(&:persisted?)
    end

    def chapter_scanlator_description
      "Читати #{chapter.display_title} \"#{chapter.fiction_title}\" у перекладі команди " \
        "\"#{chapter.scanlators.map(&:title).to_sentence}\"."
    end

    def publication = meta_assign(:publication)

    def fiction = meta_assign(:fiction)

    def chapter = meta_assign(:chapter)

    def youtube_video = meta_assign(:youtube_video)

    def bookshelf = meta_assign(:bookshelf)

    def scanlator = meta_assign(:scanlator)

    def genre = meta_assign(:genre)
  end
end
