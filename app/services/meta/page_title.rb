# frozen_string_literal: true

module Meta
  # Resolves page <title> copy from search terms, I18n, and page assigns.
  class PageTitle
    DEFAULT_TITLE = 'Бака: про аніме українською'
    CONTENT_RECORD_PRIORITY = %i[chapter youtube_video scanlator user bookshelf].freeze

    def initialize(**context)
      @context = context
    end

    def resolve
      title_from_search ||
        title_from_i18n ||
        title_from_record ||
        default_title
    end

    private

    attr_reader :context

    def title_from_search
      return unless context[:search_index_page]

      "#{context.fetch(:search_terms).to_sentence} | Бака"
    end

    def title_from_i18n
      request_path = context[:request_path]
      return unless request_path && PageDescription.static_path?(request_path)

      I18n.t("meta.title.#{context[:controller_name]}.#{context[:action_name]}")
    end

    def title_from_record
      title_from_content_record || title_from_genre
    end

    def title_from_content_record
      CONTENT_RECORD_PRIORITY.each do |kind|
        record = context[kind]
        next unless record&.persisted?

        return send(:"#{kind}_title", record)
      end

      nil
    end

    def title_from_genre
      return unless context[:genre_show_page]

      genre = context[:genre]
      return unless genre&.persisted?

      I18n.t('meta.title.genres.show', name: genre.name)
    end

    def default_title
      [context[:publication], context[:fiction]].compact.map(&:title).first || DEFAULT_TITLE
    end

    def chapter_title(chapter)
      "#{chapter.fiction_title} | #{chapter.display_title}"
    end

    def youtube_video_title(video)
      video.title
    end

    def scanlator_title(scanlator)
      "#{scanlator.title} | Переклади Ранобе | Бака"
    end

    def user_title(user)
      "#{user.name} | Профіль Користувача | Бака"
    end

    def bookshelf_title(bookshelf)
      "#{bookshelf.title} | Бака"
    end
  end
end
