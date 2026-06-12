# frozen_string_literal: true

require 'test_helper'

module Ui
  class GenrePageTagListComponentTest < ViewComponentTestCase
    test 'renders genre links' do
      render_inline(
        GenrePageTagListComponent.new(
          genres: [{ name: 'Бойовик', slug: 'action' }, { name: 'Фентезі', slug: 'fantasy' }]
        )
      )

      assert_selector 'a', text: 'Бойовик', count: 1
      assert_selector 'a', text: 'Фентезі', count: 1
    end

    test 'renders explicit genres as red adult tags' do
      render_inline(
        GenrePageTagListComponent.new(
          genres: [
            { name: 'Романтика', slug: 'romance' },
            { name: 'BL', slug: 'bl' }
          ]
        )
      )

      assert_selector 'a.bg-rose-200', text: 'BL'
      assert_selector 'a.bg-rose-200 svg'
      assert_selector 'a.border-slate-300.bg-white', text: 'Романтика'
    end

    test 'orders explicit genres before others' do
      render_inline(
        GenrePageTagListComponent.new(
          genres: [
            { name: 'Романтика', slug: 'romance' },
            { name: 'BL', slug: 'bl' }
          ]
        )
      )

      assert_text(/BL.*Романтика/m)
    end

    test 'clusters explicit genres side by side' do
      render_inline(
        GenrePageTagListComponent.new(
          genres: [
            { name: 'Драма', slug: 'drama' },
            { name: 'BL', slug: 'bl' },
            { name: 'ЛГБТ', slug: 'lgbt' }
          ]
        )
      )

      assert_selector 'div.inline-flex.flex-nowrap.items-center.gap-1', count: 1
      assert_selector 'div.inline-flex.flex-nowrap a.bg-rose-200', count: 2
    end

    test 'does not render when genres empty' do
      render_inline(GenrePageTagListComponent.new(genres: []))

      assert_no_selector 'a'
    end
  end
end
