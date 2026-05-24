# frozen_string_literal: true

module StructuredData
  # Controller/action predicates and URL helpers for JSON-LD meta tags.
  module JsonLdPageHelper
    def article_meta?
      tales_show_page?
    end

    def chapter_reader_meta?
      chapters_show_page?
    end

    def fiction_reader_meta?
      fictions_show_page?
    end

    def about_page_meta?
      pages_about_page?
    end

    def article_author_meta?(publication)
      tales_show_page? && publication&.persisted?
    end

    def fiction_author_meta?(fiction)
      fiction_reader_meta? && fiction&.persisted?
    end

    def fiction_author_url(fiction)
      fiction_author_search_url(fiction)
    end

    def profile_page_meta?
      scanlators_show_page?
    end

    def user_profile_meta?
      profiles_show_page?
    end

    def video_meta?
      youtube_videos_show_page?
    end

    private

    def tales_show_page?
      controller_name.to_sym == :tales && action_name.to_sym == :show
    end

    def chapters_show_page?
      controller_name.to_sym == :chapters && action_name.to_sym == :show
    end

    def fictions_show_page?
      controller_name.to_sym == :fictions && action_name.to_sym == :show
    end

    def pages_about_page?
      controller_name.to_sym == :pages && action_name.to_sym == :about
    end

    def scanlators_show_page?
      controller_name.to_sym == :scanlators && action_name.to_sym == :show
    end

    def profiles_show_page?
      controller_name.to_sym == :profiles && action_name.to_sym == :show
    end

    def youtube_videos_show_page?
      controller_name.to_sym == :youtube_videos && action_name.to_sym == :show
    end

    def default_public_url_options
      Rails.application.config.action_mailer.default_url_options.symbolize_keys
    end

    def fiction_author_search_url(fiction)
      search_index_url(search: [fiction.author], only_path: false, **default_public_url_options)
    end
  end
end
