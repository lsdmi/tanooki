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

  test 'continue on a chapter hidden by a takedown goes to the fiction page' do
    hidden = license_past_the_preview
    @reading.update!(chapter: hidden, resume_at: Time.current)

    get library_url(section: :active)

    assert_select "#reading-progress-#{@reading.id} a[href=?]", fiction_path(@fiction), text: /Читати далі/
    assert_select "#reading-progress-#{@reading.id} a[href^=?]", chapter_path(hidden), count: 0
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
