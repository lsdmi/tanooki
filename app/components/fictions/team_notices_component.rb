# frozen_string_literal: true

module Fictions
  # «Оголошення» in the About tab: every attached team's `notice`, each with the team's avatar and name
  # (Figma «Translator Note» 10076:5647). Team-wide notices only, no archive (D8).
  class TeamNoticesComponent < ViewComponent::Base
    include ExternalUrls::UrlsHelper
    include Meta::CoverUrlsHelper

    LINK_CLASS = 'font-medium text-fg-brand underline underline-offset-2 hover:text-brand-hover break-words'

    def initialize(fiction:)
      super()
      @fiction = fiction
    end

    def render?
      teams.any?
    end

    private

    attr_reader :fiction

    def teams
      @teams ||= fiction.scanlators.select { |scanlator| scanlator.notice.present? }
    end
  end
end
