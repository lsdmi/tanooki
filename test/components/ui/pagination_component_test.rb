# frozen_string_literal: true

require 'test_helper'

module Ui
  class PaginationComponentTest < ViewComponentTestCase
    test 'renders nothing when only one page' do
      pagy = Pagy.new(count: 5, page: 1, items: 10)

      render_inline(PaginationComponent.new(pagy: pagy))

      assert_no_selector 'nav'
    end

    test 'renders translate-style pagination with current page highlighted' do
      pagy = Pagy.new(count: 50, page: 2, items: 10)

      render_inline(PaginationComponent.new(pagy: pagy, onclick: ->(page) { "loadPage(#{page})" }))

      assert_selector 'nav[aria-label="Сторінок"]'
      assert_selector 'span.bg-cyan-700', text: '2'
      assert_selector 'button[onclick="loadPage(1)"]', text: '‹'
      assert_selector 'button[onclick="loadPage(3)"]', text: '›'
    end

    test 'renders turbo form buttons for frame navigation' do
      pagy = Pagy.new(count: 50, page: 1, items: 10)

      with_request_url('/fictions') do
        render_inline(
          PaginationComponent.new(
            pagy: pagy,
            frame_id: 'fiction-list-page',
            custom_params: { genre: '3' }
          )
        )
      end

      assert_selector 'form[data-turbo-frame="fiction-list-page"]'
      assert_selector 'span.bg-cyan-700', text: '1'
    end

    test 'uses explicit form_path instead of request.path' do
      pagy = Pagy.new(count: 30, page: 2, items: 10)

      with_request_url('/reading_progresses/13377') do
        render_inline(
          PaginationComponent.new(
            pagy: pagy,
            form_path: '/library',
            custom_params: { section: 'active' }
          )
        )
      end

      assert_selector 'form[action="/library"]', text: '‹'
      assert_selector 'form[action="/library"] input[name="page"][value="1"]', visible: :hidden
      assert_selector 'form[action="/library"] input[name="section"][value="active"]', visible: :hidden
      assert_selector 'form[action="/library"] input[name="page"][value="3"]', visible: :hidden
    end
  end
end
