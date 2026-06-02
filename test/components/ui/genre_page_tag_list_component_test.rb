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

    test 'renders explicit genres as red adult tags before others' do
      render_inline(
        GenrePageTagListComponent.new(
          genres: [
            { name: 'Романтика', slug: 'romance' },
            { name: 'BL', slug: 'bl' }
          ]
        )
      )

      assert_selector 'a.bg-orange-600', text: 'BL'
      assert_selector 'a.bg-orange-600 svg'
      assert_selector 'a.border-slate-300.bg-white', text: 'Романтика'
      assert_text(/BL.*Романтика/m)
    end

    test 'does not render when genres empty' do
      render_inline(GenrePageTagListComponent.new(genres: []))

      assert_no_selector 'a'
    end
  end
end
