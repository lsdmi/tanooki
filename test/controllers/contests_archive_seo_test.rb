# frozen_string_literal: true

require 'test_helper'

class ContestsArchiveSeoTest < ActionDispatch::IntegrationTest
  test 'archive show lists other public archives' do
    other = contests(:judging)
    other.update!(
      slug: 'ii-konkurs-ranobe',
      title: 'II конкурс ранобе',
      tagline: 'Переклади, архів',
      results_published_at: 1.day.ago
    )

    get contest_path(contests(:results))

    assert_response :success
    assert_select '#other-archives a[href=?] span.font-semibold', contest_path(other), text: other.title
    assert_select '#other-archives a[href=?]', rules_path(anchor: 'contest-rules')
  end

  test 'archive show rules section links to site contest rules' do
    get contest_path(contests(:results))

    assert_response :success
    assert_select '#rules a[href=?]', rules_path(anchor: 'contest-rules'),
                  text: I18n.t('contests.show.rules.site_rules_link')
  end

  test 'guest archive show preloads hero cover in head' do
    contest = contests(:results)
    contest.cover.attach(
      io: Rails.root.join('test/fixtures/files/cover_valid.webp').open,
      filename: 'cover.webp',
      content_type: 'image/webp'
    )

    get contest_path(contest)

    assert_response :success
    assert_select 'head link[rel="preload"][as="image"][href*="rails/active_storage"]', minimum: 1
    assert_select '#hero img[alt=""][fetchpriority="high"]', count: 1
  end
end
