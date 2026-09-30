# frozen_string_literal: true

module Ui
  # Status notice for a fiction: age rating, licence, announced / dropped / finished translation.
  # :scrim and :tinted go on top of the hero image; :light is the band outside it.
  class NoticeComponent < ViewComponent::Base
    include NoticeComponentStyles

    KINDS = {
      adult: { family: :danger, icon: :triangle_alert },
      teen: { family: :warning, icon: :triangle_alert },
      licensed: { family: :licensed, icon: :lock },
      dropped: { family: :warning, icon: :circle_pause },
      announced: { family: :info, icon: :megaphone },
      finished: { family: :success, icon: :circle_check_big }
    }.freeze
    STYLES = STYLE_CLASSES.keys.freeze

    renders_one :action

    def initialize(kind:, title:, body: nil, style: :light, html: {})
      super()
      @kind = kind.to_sym
      @style = style.to_sym
      @title = title
      @body = body
      @html = html
      raise ArgumentError, "unknown kind: #{kind}" unless KINDS.key?(@kind)
      raise ArgumentError, "unknown style: #{style}" unless STYLES.include?(@style)
    end

    private

    attr_reader :kind, :style, :title, :body, :html

    def light?
      style == :light
    end

    def family
      FAMILY_CLASSES.fetch(KINDS.fetch(kind)[:family])
    end

    def icon_paths
      ICON_PATHS.fetch(KINDS.fetch(kind)[:icon])
    end

    def body_content
      content.presence || body
    end

    def root_attributes
      html.except(:class).merge(role: 'note', class: root_classes)
    end

    def root_classes
      ['flex flex-wrap items-start gap-3 md:flex-nowrap', STYLE_CLASSES.fetch(style), tone_classes, html[:class]]
        .compact.join(' ')
    end

    def tone_classes
      case style
      when :light then family[:light_bg]
      when :tinted then "#{family[:media]} #{family[:tinted_bg]}"
      else family[:media]
      end
    end

    def icon_classes
      light? ? "size-4 mt-0.5 #{family[:light_title]}" : "size-5 md:size-6 #{family[:media_title]}"
    end

    def text_classes
      light? ? 'flex min-w-0 flex-1 flex-col gap-1 md:flex-row md:gap-3' : 'flex min-w-0 flex-1 flex-col gap-1'
    end

    def title_classes
      size = light? ? 'text-sm' : 'text-xs md:text-sm'
      "#{size} font-semibold leading-5 #{light? ? family[:light_title] : family[:media_title]}"
    end

    def body_classes
      size = light? ? 'text-sm' : 'text-xs md:text-sm'
      "#{size} leading-5 #{light? ? 'text-fg-secondary' : family[:media_body]}"
    end

    # Below the text on mobile, indented past the icon; to the right on desktop.
    def action_classes
      "basis-full #{light? ? 'pl-7' : 'pl-8'} md:basis-auto md:shrink-0 md:self-center md:pl-0"
    end
  end
end
