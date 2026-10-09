# frozen_string_literal: true

require 'test_helper'

class FictionsControllerLicenseTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  SOURCE = { license_publisher: 'Видавництво Тест', license_url: 'https://example.test/book' }.freeze

  setup do
    @fiction = fictions(:one)
    @editor = users(:user_two)
    ScanlatorUser.create!(user: @editor, scanlator: scanlators(:one))
    sign_in @editor
  end

  test 'edit form offers the license checkbox unchecked with the first-mark confirm' do
    get edit_fiction_url(@fiction)

    assert_select 'input#fiction_licensed[type=checkbox]:not([checked])'
    assert_select '#fiction_license[data-license-mark-marked-value=false] template a[href=?]', '/rules#licensed-content'
    assert_includes response.body, 'лишаться лише перші 6 як ознайомчий фрагмент'
  end

  test 'the new fiction form has no license block' do
    get new_fiction_url

    assert_select '#fiction_license', count: 0
  end

  test 'update marks the license with its source' do
    patch fiction_url(@fiction), params: { fiction: { scanlator_ids: [1], licensed: '1', **SOURCE } }

    assert_redirected_to fiction_path(@fiction)
    assert_predicate @fiction.reload, :licensed?
    assert_equal SOURCE.values, [@fiction.license_publisher, @fiction.license_url]
  end

  test 'update without a source re-renders the form with the error' do
    patch fiction_url(@fiction), params: { fiction: { scanlator_ids: [1], licensed: '1', license_publisher: ' ' } }

    assert_response :unprocessable_content
    assert_select '#fiction_license p', text: /обов'язкові для ліцензованого твору/
    assert_not_predicate @fiction.reload, :licensed?
  end

  test 'within the grace period the team sees the deadline and can unmark' do
    license!(2.hours.ago)

    get edit_fiction_url(@fiction)

    assert_select '#fiction_license p', text: /Самостійно зняти позначку можна до/
    patch fiction_url(@fiction), params: { fiction: { scanlator_ids: [1], licensed: '0' } }

    assert_not_predicate @fiction.reload, :licensed?
  end

  test 'after the grace period the team sees the Telegram note instead of the checkbox' do
    license!(2.days.ago)

    get edit_fiction_url(@fiction)

    assert_select 'input#fiction_licensed', count: 0
    assert_select '#fiction_license p', text: /Позначку може зняти лише адміністрація/
  end

  test 'a forced unmark after the grace period keeps the license and warns' do
    license!(2.days.ago)

    patch fiction_url(@fiction), params: { fiction: { scanlator_ids: [1], licensed: '0' } }

    assert_redirected_to fiction_path(@fiction)
    assert_equal I18n.t('fictions.license.frozen'), flash[:alert]
    assert_predicate @fiction.reload, :licensed?
  end

  test 'an admin unmarks after the grace period' do
    license!(2.days.ago)
    sign_in users(:user_one)

    patch fiction_url(@fiction), params: { fiction: { scanlator_ids: [1], licensed: '0' } }

    assert_nil flash[:alert]
    assert_not_predicate @fiction.reload, :licensed?
  end

  test 'only an admin gets the hide chapters checkbox' do
    license!(2.days.ago)

    get edit_fiction_url(@fiction)

    assert_select 'input#fiction_chapters_hidden', count: 0

    sign_in users(:user_one)
    get edit_fiction_url(@fiction)

    assert_select 'input#fiction_chapters_hidden[type=checkbox]:not([checked])'
  end

  test 'an admin hides chapters from the edit form' do
    license!(2.days.ago)
    sign_in users(:user_one)

    fields = { scanlator_ids: [1], licensed: '1', chapters_hidden: '1', **SOURCE }
    patch fiction_url(@fiction), params: { fiction: fields }

    assert_predicate @fiction.reload, :chapters_hidden?
  end

  test 'the rules page explains licensed works' do
    get rules_url

    assert_select '#licensed-content p', text: /Відповідальність за вчасну позначку несе команда/
    assert_select '#rights-holders a[href=?]', ExternalUrls.site_url
  end

  private

  def license!(at)
    @fiction.update!(licensed_at: at, license_publisher: SOURCE[:license_publisher])
  end
end
