# frozen_string_literal: true

module Fictions
  # Top of fiction#show (Figma «Hero band» 10088:10422): a cropped copy of the cover under a scrim as the backdrop,
  # with the cover, badges, title, stats, credits and the main action on top. Logged-in vs logged-out only changes
  # the actions (Fictions::HeroActionsComponent). The status notice goes in the `notice` slot above the cover.
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

    def cover_tag(classes:, **)
      cover_card_picture_tag(fiction.cover, class: classes, width: 400, height: 600, loading: 'eager',
                                            decoding: 'async', **)
    end

    def original_title
      [fiction.english_title, fiction.alternative_title].compact_blank.uniq.join(' · ').presence
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
        [:list, t('fictions.hero.stats.chapters', count: fiction.chapter_count)],
        [:bookmark, t('fictions.hero.stats.bookmarks', count: presenter.bookmarks_total_count)]
      ]
    end

    def scanlators
      @scanlators ||= fiction.scanlators.to_a
    end
  end
end
