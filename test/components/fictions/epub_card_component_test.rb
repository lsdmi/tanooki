# frozen_string_literal: true

require 'test_helper'

module Fictions
  class EpubCardComponentTest < ViewComponentTestCase
    setup do
      @fiction = fictions(:one)
    end

    test 'a reader is pointed to the Chapters tab' do
      with_epub_support(:all) do
        render_inline(EpubCardComponent.new(fiction: @fiction, user: users(:user_one)))
      end

      assert_selector 'a[href="#chapters"][data-action="tabs#jump"][data-tabs-tab-param="chapters"]',
                      text: /Завантаження EPUB.*По томах у вкладці «Розділи»/m
    end

    test 'a guest is asked to log in' do
      with_epub_support(:mixed) do
        render_inline(EpubCardComponent.new(fiction: @fiction, user: nil))
      end

      assert_selector 'a[href^="/login"]', text: /Увійдіть, щоб завантажити.*Увійти/m
    end

    test 'no card when no section allows EPUB' do
      with_epub_support(:none) do
        render_inline(EpubCardComponent.new(fiction: @fiction, user: users(:user_one)))
      end

      assert_no_selector 'a'
    end

    private

    def with_epub_support(support, &)
      Library::ReadingState.stub(:fiction_epub_download_support, support, &)
    end
  end
end
