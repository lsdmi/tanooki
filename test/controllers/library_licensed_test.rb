# frozen_string_literal: true

require 'test_helper'

class LibraryLicensedTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
    @reading = reading_progresses(:one)
    @reading.update!(status: :active)
    @fiction = @reading.fiction
  end

  test 'a licensed work keeps its shelf in the library with no licensed tag' do
    @fiction.scanlator_ids = @fiction.scanlators.ids
    @fiction.update!(licensed_at: 1.day.ago, license_publisher: 'Видавництво Тест')

    get library_url(section: :active)

    assert_select "#reading-progress-#{@reading.id}"
    assert_select "#reading-progress-#{@reading.id} span", text: 'Ліцензовано', count: 0
  end

  test 'a reader stopped on a chapter hidden by the licence gets the licensed row' do
    hidden = license_past_the_preview
    @reading.update!(chapter: hidden, resume_at: Time.current)

    get library_url(section: :active)

    row = "#reading-progress-#{@reading.id}"

    assert_select "#{row} p", text: 'прочитано 7 до ліцензування'
    assert_select "#{row} a[href=?]", fiction_path(@fiction, anchor: 'chapters'), text: 'Розділи'
    assert_select "#{row} a[href^=?]", chapter_path(hidden), count: 0
  end

  test 'the licensed row reads on in the official edition' do
    @reading.update!(chapter: license_past_the_preview, resume_at: Time.current)
    @fiction.update!(license_url: 'https://example.com/book')

    get library_url(section: :active)

    assert_select "#reading-progress-#{@reading.id} a[href='https://example.com/book']",
                  text: I18n.t('fictions.license.official_edition')
  end

  private

  def license_past_the_preview
    (3..7).each do |number|
      Chapter.create!(fiction: @fiction, user: users(:user_one), title: "Chapter #{number}", number:,
                      content: 'x' * 500, scanlator_ids: [scanlators(:one).id])
    end
    @fiction.scanlator_ids = @fiction.scanlators.ids
    @fiction.update!(licensed_at: 1.day.ago, license_publisher: 'Видавництво Тест')
    @fiction.chapters.find_by(number: 7)
  end
end
