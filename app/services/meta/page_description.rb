# frozen_string_literal: true

module Meta
  # Resolves <meta name="description"> copy from page assigns, routes, and I18n.
  class PageDescription
    include Rails.application.routes.url_helpers

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
    SENTENCE_BOUNDARY = /(?<=[.?!])\s+/

    def self.static_path?(request_path)
      helpers = Rails.application.routes.url_helpers
      STATIC_DESCRIPTION_PATHS.any? { |path_helper| request_path == helpers.public_send(path_helper) }
    end

    def initialize(**context)
      @context = context
    end

    def resolve
      description_from_record ||
        description_from_genre ||
        description_from_scanlator ||
        description_from_static_path ||
        DEFAULT_DESCRIPTION
    end

    private

    def description_from_record
      object_description if description_object.present?
    end

    def description_from_genre
      genre_meta_description if context[:genre_show_page]
    end

    def description_from_scanlator
      scanlator_description if scanlator&.persisted?
    end

    def description_from_static_path
      I18n.t("meta.description.#{context[:controller_name]}.#{context[:action_name]}") if static_description_path?
    end

    def static_description_path?
      self.class.static_path?(context.fetch(:request_path))
    end

    def description_object
      [publication, fiction, chapter&.fiction, youtube_video, bookshelf].compact.find(&:persisted?)
    end

    def object_description
      %i[publication fiction chapter bookshelf].each do |kind|
        record = context[kind]
        next unless record&.persisted?

        return send(:"#{kind}_description")
      end

      youtube_video&.description
    end

    def chapter_description
      return chapter_scanlator_description if chapter.scanlators.any?

      "Читати #{chapter.display_title} \"#{chapter.fiction_title}\" за авторства #{chapter.author}."
    end

    def chapter_scanlator_description
      "Читати #{chapter.display_title} \"#{chapter.fiction_title}\" у перекладі команди " \
        "\"#{chapter.scanlators.map(&:title).to_sentence}\"."
    end

    def fiction_description
      if fiction.scanlators.any?
        "Читати ранобе \"#{fiction.title}\" у перекладі команди \"#{fiction.scanlators.map(&:title).to_sentence}\"."
      else
        "Читати ранобе \"#{fiction.title}\" за авторства \"#{fiction.author}\"."
      end
    end

    def bookshelf_description
      fiction_titles = bookshelf.fictions.limit(3).pluck(:title).to_sentence
      "#{bookshelf.title} від #{bookshelf.user_name}. #{bookshelf.description}." \
        "Зокрема #{fiction_titles}#{bookshelf.fictions.count > 3 ? ' та інш твори' : ''}."
    end

    def publication_description
      first_sentence(publication.description.to_plain_text)
    end

    def scanlator_description
      "#{scanlator.title} перекладають ранобе та фанфіки українською " \
        "(#{scanlator.fictions.map(&:title).to_sentence.truncate(75)}). " \
        'Читайте онлайн на Бака!'
    end

    def genre_meta_description
      I18n.t('meta.description.genres.show', name: genre.name, count: genre.fictions.count)
    end

    def first_sentence(text)
      text.to_s.split(SENTENCE_BOUNDARY).first.presence || text.to_s
    end

    def publication = context[:publication]

    def fiction = context[:fiction]

    def chapter = context[:chapter]

    def youtube_video = context[:youtube_video]

    def bookshelf = context[:bookshelf]

    def scanlator = context[:scanlator]

    def genre = context[:genre]

    attr_reader :context
  end
end
