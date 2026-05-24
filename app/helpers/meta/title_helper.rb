# frozen_string_literal: true

module Meta
  # Page <title> resolution for layouts and Open Graph.
  module TitleHelper
    def meta_title
      meta_title_from_search ||
        meta_title_from_i18n ||
        meta_title_from_record ||
        default_meta_title
    end

    private

    def meta_title_from_search
      search_meta_title if search_index_path?
    end

    def meta_title_from_i18n
      I18n.t("meta.title.#{controller_name}.#{action_name}") if consts_paths?
    end

    def meta_title_from_record
      meta_title_from_content_record || meta_title_from_genre
    end

    def meta_title_from_content_record
      chapter_title if meta_assign_persisted?(:chapter)
      youtube_video_meta_title if meta_assign_persisted(:youtube_video)
      scanlator_meta_title if meta_assign_persisted(:scanlator)
      user_profile_meta_title if meta_assign_persisted(:user)
      bookshelf_meta_title if meta_assign_persisted?(:bookshelf)
    end

    def meta_title_from_genre
      genre_meta_title if genre_show_page? && meta_assign_persisted(:genre)
    end

    def search_index_path?
      request.path == search_index_path
    end

    def search_meta_title
      "#{params[:search].to_sentence} | Бака"
    end

    def youtube_video_meta_title
      meta_assign(:youtube_video).title
    end

    def scanlator_meta_title
      "#{meta_assign(:scanlator).title} | Переклади Ранобе | Бака"
    end

    def user_profile_meta_title
      "#{meta_assign(:user).name} | Профіль Користувача | Бака"
    end

    def bookshelf_meta_title
      "#{meta_assign(:bookshelf).title} | Бака"
    end

    def genre_meta_title
      I18n.t('meta.title.genres.show', name: meta_assign(:genre).name)
    end

    def default_meta_title
      [meta_assign(:publication), meta_assign(:fiction)].compact.map(&:title).first ||
        'Бака: про аніме українською'
    end

    def chapter_title
      chapter = meta_assign(:chapter)
      "#{chapter.fiction_title} | #{chapter.display_title}"
    end
  end
end
