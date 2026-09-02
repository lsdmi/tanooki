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

    test 'pins the row to the bottom by default and opts out on request' do
      genres = [{ name: 'Бойовик', slug: 'action' }]

      render_inline(GenrePageTagListComponent.new(genres: genres))

      assert_selector 'div.mt-auto.pt-4'

      render_inline(GenrePageTagListComponent.new(genres: genres, pin_bottom: false))

      assert_no_selector 'div.mt-auto'
    end

    test 'forwards tag_html to each pill' do
      render_inline(
        GenrePageTagListComponent.new(
          genres: [{ name: 'Бойовик', slug: 'action' }, { name: 'BL', slug: 'bl' }],
          tag_html: { data: { turbo_frame: '_top' } }
        )
      )

      assert_selector 'a[data-turbo-frame="_top"]', count: 2
    end

    test 'compact_max hides the overflow pills below lg and adds a counter' do
      render_inline(
        GenrePageTagListComponent.new(
          genres: [
            { name: 'Бойовик', slug: 'action' },
            { name: 'Ісекай', slug: 'isekai' },
            { name: 'Комедія', slug: 'comedy' }
          ],
          compact_max: 1
        )
      )

      assert_selector 'a:not(.max-lg\\:hidden)', text: 'Бойовик'
      assert_selector 'a.max-lg\\:hidden', count: 2
      assert_selector 'span.lg\\:hidden', text: '+2'
    end

    test 'compact_max adds no counter when it covers every genre' do
      render_inline(
        GenrePageTagListComponent.new(
          genres: [{ name: 'Бойовик', slug: 'action' }],
          compact_max: 1
        )
      )

      assert_no_selector 'span.lg\\:hidden'
      assert_no_selector '.max-lg\\:hidden'
    end

    test 'does not render when genres empty' do
      render_inline(GenrePageTagListComponent.new(genres: []))

      assert_no_selector 'a'
    end
  end
end
