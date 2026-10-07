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

  test 'a licensed work in the library keeps its shelf and gets the licensed tag' do
    @fiction.scanlator_ids = @fiction.scanlators.ids
    @fiction.update!(licensed_at: 1.day.ago, license_publisher: 'Видавництво Тест')

    get library_url(section: :active)

    assert_select "#reading-progress-#{@reading.id} span", text: 'Ліцензовано'
  end

  test 'an unlicensed work has no licensed tag' do
    get library_url(section: :active)

    assert_select "#reading-progress-#{@reading.id} span", text: 'Ліцензовано', count: 0
  end
end
