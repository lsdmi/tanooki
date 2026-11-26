# frozen_string_literal: true

module Fictions
  module Reviews
    # «Усі / Відгуки (N)» above the comments of a fiction. Shown only when the fiction has reviews, so a fiction
    # without any keeps the plain comments tab. Links stay inside the comments frame and keep the order.
    class FilterComponent < ViewComponent::Base
      CHIP_CLASS = 'inline-flex items-center rounded-full px-3 py-1 text-xs/5 font-medium ring-1 ring-inset ' \
                   'transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-line-strong'
      ACTIVE_CLASS = 'bg-brand-subtle text-fg-brand ring-brand'
      IDLE_CLASS = 'text-fg-secondary ring-line hover:text-fg'

      def initialize(fiction:, order:, reviews_only:)
        super()
        @fiction = fiction
        @order = order
        @reviews_only = reviews_only
      end

      def render? = fiction.reviews_count.positive?

      private

      attr_reader :fiction, :order, :reviews_only

      def chip_class(active) = "#{CHIP_CLASS} #{active ? ACTIVE_CLASS : IDLE_CLASS}"

      def all_path = comments_fiction_path(fiction, order:)

      def reviews_path = comments_fiction_path(fiction, order:, filter: 'reviews')
    end
  end
end
