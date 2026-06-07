# frozen_string_literal: true

module Chapters
  # Chapter reader comments drawer labels and copy.
  module CommentsDrawerHelper
    def chapter_comments_drawer_subtitle(count)
      I18n.t('chapters.reader_comments_drawer.count', count: count)
    end

    def comment_posted_ago(comment)
      "#{time_ago_in_words(comment.created_at, locale: :uk)} #{t('chapters.reader_comments_drawer.ago_suffix')}"
    end

    def immersive_comments_drawer_form?
      return true if chapters_show_page?

      referer = request.referer
      referer.present? && referer.include?('/chapters/')
    end
  end
end
