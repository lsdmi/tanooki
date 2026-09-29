# frozen_string_literal: true

require 'test_helper'

# Guests keep reading progress on their device (P3.1). The server only renders what the device-side controllers need.
class GuestReadingMarkupTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  READER = '.immersive-reader[data-controller~=reading-progress]'
  GUEST_CTA = 'div[data-controller=guest-continue]'

  setup do
    @fiction = fictions(:one)
    @first = chapters(:one)
    @latest = chapters(:two)
  end

  test 'a guest chapter page keeps progress on the device with the ids and paths it needs' do
    get chapter_url(@first)

    assert_select "#{READER}[data-controller~=guest-resume][data-reading-progress-guest-value=true]" \
                  "[data-reading-progress-fiction-id-value='#{@fiction.id}']" \
                  "[data-reading-progress-chapter-id-value='#{@first.id}']" \
                  '[data-reading-progress-chapter-path-value=?][data-reading-progress-next-path-value=?]',
                  chapter_path(@first), chapter_path(@latest)
  end

  test 'a guest gets a hidden banner whose percent the device fills in' do
    get chapter_url(@first)

    assert_select "#{READER}[data-guest-resume-label-value=?]", 'Продовжити з {percent}%'
    assert_select 'section[data-reading-resume-target=banner][hidden] span[data-guest-resume-target=label]'
    assert_select '[data-reading-progress-hold-value], [data-controller~=reading-resume]', count: 0
  end

  test 'signed-in readers report to the server with no guest values' do
    sign_in users(:user_one)
    get chapter_url(@first)

    assert_select "#{READER}[data-reading-progress-url-value=?]", record_progress_chapter_path(@first)
    assert_select '[data-reading-progress-guest-value], [data-controller~=guest-resume], [data-guest-resume-target]',
                  count: 0
  end

  test 'the guest fiction page CTA can switch to continue from the device record' do
    get fiction_url(@fiction)

    assert_select "#{GUEST_CTA}[data-guest-continue-fiction-id-value='#{@fiction.id}']" \
                  "[data-guest-continue-latest-chapter-id-value='#{@latest.id}']" \
                  '[data-guest-continue-read-path-value=?][data-guest-continue-continue-label-value=?]',
                  chapter_path(@first), 'Продовжити' do
      assert_select 'a[data-guest-continue-target=link][href=?] span[data-guest-continue-target=label]',
                    chapter_path(@first), text: 'Читати'
      assert_select 'a[data-guest-continue-target=fromStart][hidden][href=?]', chapter_path(@first)
    end
  end

  test 'the signed-in fiction page CTA stays server-rendered' do
    sign_in users(:user_one)
    get fiction_url(@fiction)

    assert_select "#{GUEST_CTA}, [data-guest-continue-target]", count: 0
  end
end
