# frozen_string_literal: true

module Fictions
  # Small purple «Ліцензовано» tag for list rows. Renders nothing for an unlicensed work.
  class LicensedTagComponent < ViewComponent::Base
    include Ui::StrokeIconHelper

    CLASSES = 'inline-flex shrink-0 items-center gap-1 self-start rounded-md bg-status-licensed-subtle-bg px-1.5 ' \
              'py-0.5 text-xs/4 font-medium text-status-licensed-solid ring-1 ring-inset ' \
              'ring-status-licensed-subtle-border dark:bg-status-licensed-on-media-bg ' \
              'dark:text-status-licensed-on-media-title dark:ring-status-licensed-on-media-border'

    def initialize(fiction:)
      super()
      @fiction = fiction
    end

    def render?
      @fiction.licensed?
    end

    def call
      tag.span(class: CLASSES) do
        safe_join([stroke_icon(:lock, 'size-3 shrink-0'), t('fictions.license.label')])
      end
    end
  end
end
