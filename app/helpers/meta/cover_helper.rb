# frozen_string_literal: true

module Meta
  # Selects the best page-specific cover candidate for meta tags.
  module CoverHelper
    include Meta::AssignsHelper

    def meta_cover
      cover_candidates.find(&:present?)
    end

    private

    def cover_candidates
      [
        object_cover(cover_object),
        assigned_youtube_video_cover,
        scanlator_cover,
        bookshelf_cover
      ]
    end

    def cover_object
      [publication, fiction, chapter&.fiction].compact.find(&:persisted?)
    end

    def object_cover(item)
      item&.cover
    end

    def scanlator_avatar
      scanlator&.avatar.presence || url_for(asset_path('scanlator_avatar.webp'))
    end

    def assigned_youtube_video_cover
      youtube_video.thumbnail if youtube_video&.persisted?
    end

    def scanlator_cover
      scanlator_avatar if scanlator&.persisted?
    end

    def bookshelf_cover
      return unless bookshelf&.persisted?

      bookshelf.fictions.joins(:cover_attachment).first&.cover ||
        url_for(asset_path('novel.webp'))
    end

    def publication
      meta_assign(:publication)
    end

    def fiction
      meta_assign(:fiction)
    end

    def chapter
      meta_assign(:chapter)
    end

    def youtube_video
      meta_assign(:youtube_video)
    end

    def scanlator
      meta_assign(:scanlator)
    end

    def bookshelf
      meta_assign(:bookshelf)
    end
  end
end
