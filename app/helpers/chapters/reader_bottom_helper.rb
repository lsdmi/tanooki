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

    def reader_outlined_button(href:, title: nil, **html_options, &)
      ui_button(as: :link, href: href, variant: :ghost, full_width: true,
                html: reader_outlined_html(title: title, **html_options), &)
    end

    def reader_outlined_html(title:, **html_options)
      {
        title: title,
        class: reader_outlined_css_class(html_options[:class]),
        **html_options.except(:class)
      }
    end

    def reader_outlined_css_class(extra_class = nil)
      ['reader-outlined-btn', 'lg:w-auto', 'lg:max-w-full', extra_class].compact.join(' ')
    end
  end
end
