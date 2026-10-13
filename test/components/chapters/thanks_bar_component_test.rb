# frozen_string_literal: true

require 'test_helper'

module Chapters
  class ThanksBarComponentTest < ViewComponent::TestCase
    setup do
      @chapter = chapters(:one)
      @reader = users(:user_two)
      ChapterThank.where(chapter: @chapter).delete_all
    end

    test 'a reader sees the thanks pill' do
      render_inline(ThanksBarComponent.new(chapter: @chapter, user: @reader))

      assert_selector 'button[aria-pressed=false]', text: /Дякую/
      assert_selector '[data-controller=chapter-thanks]'
      assert_text 'Переклад: One'
    end

    test 'a thanked reader sees the status and the support line' do
      scanlators(:one).update!(bank_url: 'https://send.monobank.ua/jar/test')
      ChapterThank.create!(user: @reader, chapter: @chapter)

      render_inline(ThanksBarComponent.new(chapter: @chapter.reload, user: @reader))

      assert_selector 'button[aria-pressed=true]', text: /Ви подякували/
      assert_text 'Дякуємо! Команда це побачить.'
      assert_link 'Підтримати →', href: 'https://send.monobank.ua/jar/test'
    end

    test 'support stays out when the team has no donation link' do
      ChapterThank.create!(user: @reader, chapter: @chapter)

      render_inline(ThanksBarComponent.new(chapter: @chapter.reload, user: @reader))

      assert_text 'Дякуємо! Команда це побачить.'
      assert_no_selector '[data-chapter-thanks-target=support]'
    end

    test 'a guest gets a login link back to the thanks block' do
      render_inline(ThanksBarComponent.new(chapter: @chapter, user: nil))

      assert_link 'Увійдіть, щоб подякувати перекладачам',
                  href: /return_to=.*#{@chapter.slug}.*chapter-thanks/
      assert_no_selector 'button[data-chapter-thanks-target=button]'
    end

    test 'the team sees the count without a toggle' do
      render_inline(ThanksBarComponent.new(chapter: @chapter.reload, user: users(:user_one)))

      assert_text 'Подяки читачів'
      assert_text I18n.t('chapters.thanks.count', count: @chapter.thanks_count)
      assert_no_selector 'button[data-chapter-thanks-target=button]'
    end
  end
end
