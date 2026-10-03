# frozen_string_literal: true

module Ui
  # Section title with a brand bar on the left (Figma «Title Container» 6023:4673): 18 px on mobile, 24 px from md.
  class SectionHeadingComponent < ViewComponent::Base
    def initialize(title:, id: nil, tag: :h2)
      super()
      @title = title
      @id = id
      @tag = tag
    end

    def call
      tag.div(class: 'flex items-stretch gap-2 md:gap-3') do
        safe_join([
                    tag.span(class: 'w-1 shrink-0 rounded-sm bg-brand', aria: { hidden: true }),
                    content_tag(@tag, @title, id: @id, class: 'text-lg/7 font-bold text-fg md:text-2xl/8')
                  ])
      end
    end
  end
end
