# frozen_string_literal: true

require 'test_helper'

class CalendarGridViewTest < ActionView::TestCase
  helper do
    def calendar_adsense_renderable? = false
  end

  test 'team support link opens the donation page in a new tab' do
    render partial: 'chapters_calendar/calendar_grid',
           locals: { fictions: [day_with(scanlator_bank_url: 'https://send.monobank.ua/jar/abc')],
                     subscriptions_filter_active: false }

    assert_select 'a[href="https://send.monobank.ua/jar/abc"][target="_blank"][rel="noopener noreferrer"]',
                  text: 'Підтримка'
  end

  test 'no support link without a donation url' do
    render partial: 'chapters_calendar/calendar_grid',
           locals: { fictions: [day_with(scanlator_bank_url: nil)], subscriptions_filter_active: false }

    assert_select 'a', text: 'Підтримка', count: 0
  end

  private

  def day_with(**update)
    fiction = fictions(:one)
    scanlator = scanlators(:one)
    {
      date: '06.10', day: 'Вівторок',
      updates: [{ chapters_count: 1, chapters_released_at: '12:00', fiction_genres: [],
                  fiction_slug: fiction.slug, fiction_title: fiction.title,
                  scanlator_slug: scanlator.slug, scanlator_title: scanlator.title, **update }]
    }
  end
end
