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

    def reader_outlined_btn_class
      'reader-outlined-btn inline-flex w-full items-center justify-center gap-1.5 rounded-lg border border-stone-200 bg-white px-3 py-2 text-sm font-medium text-stone-700 shadow-sm transition-colors hover:border-stone-300 hover:bg-stone-50 focus:outline-none focus-visible:ring-2 focus-visible:ring-stone-400 focus-visible:ring-offset-2 focus-visible:ring-offset-white dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-200 dark:hover:border-zinc-600 dark:hover:bg-zinc-800/80 dark:focus-visible:ring-zinc-500 dark:focus-visible:ring-offset-zinc-900 lg:w-auto lg:max-w-full'
    end
  end
end
