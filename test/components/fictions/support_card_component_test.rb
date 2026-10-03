# frozen_string_literal: true

require 'test_helper'

module Fictions
  class SupportCardComponentTest < ViewComponentTestCase
    setup do
      @fiction = fictions(:one)
    end

    test 'shows the mascot, title, copy and a support link opening in a new tab' do
      @fiction.scanlators.to_a.first.bank_url = 'https://send.monobank.ua/jar/example'

      render_inline(SupportCardComponent.new(fiction: @fiction))

      assert_selector 'h2#fiction-support-title', text: 'Підтримати Команду'
      assert_selector 'img[src*="mascot"]', count: 2, visible: :all
      assert_selector 'a[href="https://send.monobank.ua/jar/example"][target="_blank"]', text: 'Підтримка'
    end

    test 'renders nothing without a team support link' do
      @fiction.scanlators.each { |team| team.bank_url = nil }

      render_inline(SupportCardComponent.new(fiction: @fiction))

      assert_no_selector 'section'
    end
  end
end
