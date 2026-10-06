# frozen_string_literal: true

module Fictions
  # «Підтримати Команду» in the About sidebar (Figma «Community Support», Dekstop=False 4151:5609): mascot, title and
  # copy in a row, a full-width «Підтримати через …» link below. The reader keeps its own wider card. Shown when a
  # team has a support link.
  class SupportCardComponent < ViewComponent::Base
    include Chapters::ReaderBottomHelper

    def initialize(fiction:, heading_id: 'fiction-support-title')
      super()
      @fiction = fiction
      @heading_id = heading_id
    end

    def render?
      fiction_reader_support?(fiction)
    end

    private

    attr_reader :fiction, :heading_id

    def href
      fiction_reader_support_url(fiction)
    end

    def label
      fiction_reader_support_label(fiction)
    end
  end
end
