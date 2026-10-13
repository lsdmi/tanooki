# frozen_string_literal: true

module Chapters
  # End-of-chapter thanks block (Figma 10167:15137): title, pill, credit, and after thanking a quiet support
  # line. Guests get a login link back to this block; the team sees the count without a toggle.
  class ThanksBarComponent < ViewComponent::Base
    include ThanksBarComponentStyles
    include Ui::StrokeIconHelper

    def initialize(chapter:, user:)
      super()
      @chapter = chapter
      @user = user
    end

    private

    attr_reader :chapter, :user

    def guest? = user.nil?

    def owner? = user&.manages_chapter?(chapter)

    def can_thank? = user && !owner? && chapter.public_visible?

    def thanked? = chapter.thanked_by?(user)

    def thanks_count = chapter.thanks_count

    def count_label = t('chapters.thanks.count', count: thanks_count)

    def title
      owner? ? t('chapters.thanks.owner_title') : t('chapters.thanks.title')
    end

    def button_label
      thanked? ? t('chapters.thanks.button_thanked') : t('chapters.thanks.button')
    end

    def pill_class
      thanked? ? PILL_THANKED : PILL_IDLE
    end

    def credit
      names = chapter.scanlators.map(&:title).compact_blank
      t('chapters.thanks.credit', teams: names.join(' · ')) if names.any?
    end

    def support_scanlator
      @support_scanlator ||= chapter.scanlators.find(&:donation_url)
    end

    def support_url = support_scanlator&.donation_url

    def show_support? = thanked? && support_url.present?

    def login_path
      new_user_session_path(return_to: chapter_path(chapter, anchor: 'chapter-thanks'))
    end

    def stimulus_data
      { controller: 'chapter-thanks', **stimulus_values, **stimulus_classes }
    end

    def stimulus_values
      {
        chapter_thanks_url_value: chapter_thanks_path(chapter),
        chapter_thanks_thanked_value: thanked?,
        chapter_thanks_idle_label_value: t('chapters.thanks.button'),
        chapter_thanks_thanked_label_value: t('chapters.thanks.button_thanked'),
        chapter_thanks_status_value: t('chapters.thanks.status_thanked'),
        chapter_thanks_error_value: t('chapters.thanks.error')
      }
    end

    def stimulus_classes
      { chapter_thanks_idle_class: PILL_IDLE, chapter_thanks_thanked_class: PILL_THANKED }
    end
  end
end
