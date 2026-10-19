# frozen_string_literal: true

module Fictions
  # Top of fiction#show (Figma «Hero band» 10088:10422): a cropped copy of the cover, washed out and fading into the
  # page, as the backdrop, with the cover, badges, title, stats, credits and the main action on top. Logged-in vs
  # logged-out only changes the actions (Fictions::HeroActionsComponent). The status notice goes in the `notice` slot
  # above the cover.
  class HeroBandComponent < ViewComponent::Base
    include Fictions::FormattingHelper
    include Meta::CoverUrlsHelper
    include Ui::StrokeIconHelper
    include HeroBandComponentStyles

    renders_one :notice

    def initialize(fiction:, presenter:, user:)
      super()
      @fiction = fiction
      @presenter = presenter
      @user = user
    end

    private

    attr_reader :fiction, :presenter, :user

    def cover?
      fiction.cover.attached?
    end

    # Prefer a thumb under the blur; if variants are unavailable this falls back to the same URL as the card img
    # so the browser fetches the cover once.
    def backdrop_image_url
      cover_thumbnail_url(fiction.cover).presence || cover_card_url(fiction.cover)
    end

    def backdrop_style
      "background-image: url('#{backdrop_image_url}')"
    end

    def cover_tag
      cover_card_picture_tag(fiction.cover, class: COVER_IMAGE, alt: fiction.title, loading: 'eager',
                                            decoding: 'async')
    end

    def original_title
      [fiction.english_title, fiction.alternative_title].compact_blank.uniq.join(' · ').presence
    end

    # The language the work was written in, not the one the team translates from (often an English translation).
    def origin_language
      return if fiction.origin.blank? || fiction.nknown?

      t(fiction.origin, scope: 'fictions.hero.origins')
    end

    def rating_text
      count, average = fiction.rating_summary
      return '—' if count.zero?

      t('fictions.hero.stats.rating', average: format('%.1f', average),
                                      ratings: t('fictions.hero.stats.ratings', count:))
    end

    # «5.1т переглядів»: the compact number always takes the genitive plural.
    def views_text
      views = fiction.views.to_i
      return t('fictions.hero.stats.views', count: views) if views < 1000

      t('fictions.hero.stats.views_compact', count: format_view_count(views))
    end

    def stats
      [
        [:eye, views_text],
        [:list, chapters_text],
        [:bookmark, t('fictions.hero.stats.bookmarks', count: presenter.bookmarks_total_count)]
      ]
    end

    def chapters_text
      return t('fictions.hero.stats.chapters', count: visible_chapter_count) unless license_cut?

      t('fictions.hero.stats.chapters_available', available: fiction.license_readable_count,
                                                  count: fiction.license_preview.released_count)
    end

    # Public slots only. A chapter on a timer is omitted until it is visible to everyone.
    def visible_chapter_count
      Catalog::ChapterSlots.call(fiction)
    end

    # Something released is no longer readable: past the preview, or all of it after the takedown.
    def license_cut?
      fiction.licensed? && fiction.license_readable_count < fiction.license_preview.released_count
    end

    def scanlators
      @scanlators ||= TeamsByChapters.call(fiction)
    end
  end
end
