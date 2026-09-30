# frozen_string_literal: true

module Ui
  # Tailwind class strings for Ui::NoticeComponent (Figma «Notice Zone», 10078:10984).
  module NoticeComponentStyles
    # scrim / tinted sit on the hero image; light is the band outside the hero.
    STYLE_CLASSES = {
      scrim: 'rounded-[10px] border bg-overlay-scrim-45 p-3 backdrop-blur-lg md:rounded-lg md:px-4',
      tinted: 'rounded-[10px] border p-3 backdrop-blur-lg md:rounded-lg md:px-4',
      light: 'px-4 py-3'
    }.freeze

    FAMILY_CLASSES = {
      danger: {
        media: 'border-status-danger-on-media-border',
        media_title: 'text-status-danger-on-media-title',
        media_body: 'text-status-danger-on-media-fg',
        tinted_bg: 'bg-status-danger-on-media-bg',
        light_bg: 'bg-status-danger-subtle-bg',
        light_title: 'text-status-danger-solid'
      },
      warning: {
        media: 'border-status-warning-on-media-border',
        media_title: 'text-status-warning-on-media-title',
        media_body: 'text-status-warning-on-media-fg',
        tinted_bg: 'bg-status-warning-on-media-bg',
        light_bg: 'bg-status-warning-subtle-bg',
        light_title: 'text-status-warning-solid'
      },
      licensed: {
        media: 'border-status-licensed-on-media-border',
        media_title: 'text-status-licensed-on-media-title',
        media_body: 'text-status-licensed-on-media-fg',
        tinted_bg: 'bg-status-licensed-on-media-bg',
        light_bg: 'bg-status-licensed-subtle-bg',
        light_title: 'text-status-licensed-solid'
      },
      info: {
        media: 'border-status-info-on-media-border',
        media_title: 'text-status-info-on-media-title',
        media_body: 'text-status-info-on-media-fg',
        tinted_bg: 'bg-status-info-on-media-bg',
        light_bg: 'bg-status-info-subtle-bg',
        light_title: 'text-status-info-solid'
      },
      success: {
        media: 'border-status-success-on-media-border',
        media_title: 'text-status-success-on-media-title',
        media_body: 'text-status-success-on-media-fg',
        tinted_bg: 'bg-status-success-on-media-bg',
        light_bg: 'bg-status-success-subtle-bg',
        light_title: 'text-status-success-solid'
      }
    }.freeze

    # Lucide paths (viewBox 24, stroke 2).
    ICON_PATHS = {
      triangle_alert: [
        'm21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3', 'M12 9v4', 'M12 17h.01'
      ],
      lock: ['M5 11h14a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2', 'M7 11V7a5 5 0 0 1 10 0v4'],
      megaphone: ['m3 11 18-5v12L3 14v-3z', 'M11.6 16.8a3 3 0 1 1-5.8-1.6'],
      circle_pause: ['M22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0', 'M10 15V9', 'M14 15V9'],
      circle_check_big: ['M21.801 10A10 10 0 1 1 17 3.335', 'm9 11 3 3L22 4']
    }.freeze
  end
end
