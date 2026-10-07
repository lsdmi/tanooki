# frozen_string_literal: true

module Fictions
  # Opens the official Ukrainian edition of a licensed work in a new tab. Renders nothing without a store URL.
  # Other options go to Ui::ButtonComponent.
  class OfficialEditionButtonComponent < ViewComponent::Base
    include Ui::StrokeIconHelper

    def initialize(fiction:, label: nil, **button)
      super()
      @fiction = fiction
      @label = label
      @button = button
    end

    def render?
      fiction.licensed? && fiction.license_url.present?
    end

    def call
      render Ui::ButtonComponent.new(label: button_label, as: :link, href: fiction.license_url,
                                     **button.except(:html), html: link_html) do
        safe_join([tag.span(button_label), stroke_icon(:external_link)])
      end
    end

    private

    attr_reader :fiction, :button

    def button_label
      @label || t('fictions.license.official_edition')
    end

    def link_html
      button.fetch(:html, {}).merge(target: '_blank', rel: 'noopener noreferrer')
    end
  end
end
