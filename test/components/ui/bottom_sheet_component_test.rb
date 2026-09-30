# frozen_string_literal: true

require 'test_helper'

module Ui
  class BottomSheetComponentTest < ViewComponentTestCase
    test 'renders a trigger wired to the controller' do
      render_sheet

      assert_selector 'div[data-controller="bottom-sheet"].relative'
      assert_selector '[data-bottom-sheet-target="trigger"][data-action="click->bottom-sheet#toggle"] button',
                      text: 'Дії'
    end

    test 'renders a hidden dialog labelled by its title, with a hidden scrim' do
      render_sheet

      assert_selector 'div#chapter-actions[role="dialog"][aria-labelledby="chapter-actions-title"][hidden]',
                      visible: :all
      assert_selector '#chapter-actions p#chapter-actions-title', text: 'Розділ 85', visible: :all
      assert_selector '[data-bottom-sheet-target="scrim"][hidden].bg-overlay-scrim-60', visible: :all
    end

    test 'is a bottom sheet on mobile and a dropdown from md' do
      render_inline(BottomSheetComponent.new(title: 'Меню')) { 'x' }

      classes = page.find('[data-bottom-sheet-target="panel"]', visible: :all)[:class]

      assert_includes classes, 'fixed inset-x-0 bottom-0'
      assert_includes classes, 'pb-[max(1.5rem,env(safe-area-inset-bottom))]'
      assert_includes classes, 'md:absolute md:inset-x-auto'
    end

    test 'aligns the dropdown to the start or the end of the trigger' do
      render_inline(BottomSheetComponent.new(title: 'Меню')) { 'x' }

      assert_includes page.find('[data-bottom-sheet-target="panel"]', visible: :all)[:class], 'md:left-0'

      render_inline(BottomSheetComponent.new(title: 'Меню', align: :end)) { 'x' }

      assert_includes page.find('[data-bottom-sheet-target="panel"]', visible: :all)[:class], 'md:right-0'
    end

    test 'works without a trigger and keeps caller data attributes' do
      html = { data: { controller: 'rows', action: 'x->rows#y' } }
      render_inline(BottomSheetComponent.new(title: 'Меню', html:)) { 'x' }

      assert_includes page.find('[data-controller="rows bottom-sheet"]')['data-action'], 'x->rows#y'
      assert_no_selector '[data-bottom-sheet-target="trigger"]'
    end

    test 'rejects unknown align' do
      assert_raises(ArgumentError) { BottomSheetComponent.new(title: 'X', align: :center) }
    end

    private

    def render_sheet
      render_inline(BottomSheetComponent.new(title: 'Розділ 85', id: 'chapter-actions')) do |sheet|
        sheet.with_trigger { '<button type="button">Дії</button>'.html_safe }
        '<button type="button">Позначити прочитаним</button>'.html_safe
      end
    end
  end
end
