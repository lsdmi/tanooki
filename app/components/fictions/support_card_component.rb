# frozen_string_literal: true

module Fictions
  # «Підтримати Команду» in the About sidebar (Figma «Community Support», Dekstop=False 4151:5609): mascot, title and
  # copy in a row, a full-width «Підтримка» link below. The reader keeps its own wider card. Shown when a team has
  # a support link.
  class SupportCardComponent < ViewComponent::Base
    include ExternalUrls::UrlsHelper
    include Chapters::ReaderBottomHelper

    def initialize(fiction:)
      super()
      @fiction = fiction
    end

    def render?
      fiction_reader_support?(fiction)
    end

    private

    attr_reader :fiction

    def href
      fiction_reader_support_url(fiction)
    end
  end
end
