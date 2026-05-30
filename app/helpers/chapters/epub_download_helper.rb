# frozen_string_literal: true

module Chapters
  # EPUB download affordances in chapter and fiction views.
  module EpubDownloadHelper
    EPUB_LOGIN_LINK_CLASS =
      'font-semibold text-stone-800 underline underline-offset-2 hover:text-stone-600 ' \
      'dark:text-gray-100 dark:hover:text-gray-300'

    def chapters_allow_epub_download?(chapters)
      Books::EpubDownloadPermission.allowed?(chapters)
    end

    def epub_download_available?(chapters)
      chapters_allow_epub_download?(chapters) && user_signed_in?
    end

    def epub_download_requires_login?(chapters)
      chapters_allow_epub_download?(chapters) && !user_signed_in?
    end

    def epub_login_link(**html_options)
      link_to(
        t('downloads.epub_export.login_link_text'),
        new_user_session_path,
        class: html_options[:class].presence || EPUB_LOGIN_LINK_CLASS,
        **html_options.except(:class)
      )
    end

    def epub_guest_login_message(fiction)
      key = if fiction_epub_download_support(fiction, viewer: nil) == :mixed
              :login_required_fiction_mixed
            else
              :login_required_fiction_all
            end
      t("downloads.epub_export.#{key}", login_link: epub_login_link).html_safe
    end

    def epub_notice_paragraph(content)
      tag.p(content, class: 'text-sm sm:text-base text-stone-600 dark:text-gray-300')
    end
  end
end
