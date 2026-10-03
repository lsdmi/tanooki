# frozen_string_literal: true

module Fictions
  # Lets another team pick up an unfinished translation: an action in the «немає розділів понад 3 місяці» notice
  # (`placement: :notice`) and a line under the chapter list (`placement: :chapters`).
  # Shown to everyone, the fiction's own team and admins included. Readers without a team are sent to create one
  # first and come back to the new chapter form.
  class ContinueTranslationComponent < ViewComponent::Base
    include Layout::TurboDriveHelper

    PLACEMENTS = %i[notice chapters].freeze
    LINK_CLASS = 'font-medium text-fg-brand underline underline-offset-2 hover:text-brand-hover'

    def initialize(fiction:, user:, placement:)
      super()
      @fiction = fiction
      @user = user
      @placement = placement.to_sym
      raise ArgumentError, "unknown placement: #{placement}" unless PLACEMENTS.include?(@placement)
    end

    def render?
      fiction.listing_state != :finished
    end

    private

    attr_reader :fiction, :user, :placement

    def href
      return new_user_session_path(return_to: new_chapter) if user.nil?

      return new_chapter if user.manages_fiction?(fiction) || user.scanlators.any?

      new_scanlator_path(return_to: new_chapter)
    end

    def new_chapter
      new_chapter_path(fiction: fiction.slug)
    end

    def label(key)
      t(user ? key : "guest_#{key}", scope: 'fictions.continue_translation')
    end
  end
end
