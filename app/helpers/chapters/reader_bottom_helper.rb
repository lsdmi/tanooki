# frozen_string_literal: true

module Chapters
  # Bottom reader grid: fiction anchor card and translator support card.
  module ReaderBottomHelper
    def fiction_reader_support?(fiction)
      fiction.scanlators.any? { |scanlator| scanlator.bank_url.present? }
    end

    def fiction_reader_support_url(fiction)
      url = fiction.scanlators.filter_map(&:bank_url).find(&:present?)
      https_url(url) if url.present?
    end

    def reader_outlined_button(href:, title: nil, **html_options, &block)
      ui_button(
        as: :link,
        href: href,
        variant: :ghost,
        full_width: true,
        html: {
          title: title,
          data: { turbo: false },
          class: ['reader-outlined-btn', 'lg:w-auto', 'lg:max-w-full', html_options[:class]].compact.join(' '),
          **html_options.except(:class)
        },
        &block
      )
    end
  end
end
