# frozen_string_literal: true

require 'test_helper'

class FictionsControllerListingEditorialTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
    @fiction = fictions(:one)
  end

  test 'edit form labels expected chapters' do
    get edit_fiction_url(@fiction)

    assert_response :success
    assert_select 'label', text: 'Очікувана кількість розділів'
  end

  test 'edit form selects ongoing and shows the three release labels' do
    get edit_fiction_url(@fiction)

    assert_select 'input[name="fiction[release]"][value=ongoing][checked]'
    assert_select 'span', text: I18n.t('fictions.form.release.paused.label')
    assert_select 'span', text: I18n.t('fictions.form.release.finished.label')
  end

  test 'edit form shows the pause and finished hints' do
    get edit_fiction_url(@fiction)

    assert_select 'p', text: I18n.t('fictions.form.release.paused.hint')
    assert_select 'p', text: I18n.t('fictions.form.release.finished.hint')
  end

  test 'edit form selects the release that matches the stored facts' do
    @fiction.update!(chapter_count: 2, paused_at: Time.current)

    get edit_fiction_url(@fiction)

    assert_select 'input[name="fiction[release]"][value=paused][checked]'

    @fiction.update!(paused_at: nil, completed_at: Time.current)

    get edit_fiction_url(@fiction)

    assert_select 'input[name="fiction[release]"][value=finished][checked]'
  end

  test 'update stamps completed_at from release finished' do
    @fiction.update!(chapter_count: 2, paused_at: 1.day.ago)

    patch fiction_url(@fiction), params: {
      fiction: { scanlator_ids: [1], release: 'finished' }
    }

    assert_redirected_to fiction_path(@fiction)
    assert_not_nil @fiction.reload.completed_at
    assert_nil @fiction.paused_at
  end

  test 'update rejects a pause when the fiction has no chapters' do
    patch fiction_url(@fiction), params: {
      fiction: { scanlator_ids: [1], release: 'paused' }
    }

    assert_response :unprocessable_content
    assert_nil @fiction.reload.paused_at
    assert_select 'p', text: I18n.t('activerecord.errors.models.fiction.attributes.paused_at.requires_chapters')
  end

  test 'a licensed fiction ignores release paused' do
    @fiction.update!(chapter_count: 2, licensed_at: Time.current, license_publisher: 'Видавництво')

    patch fiction_url(@fiction), params: {
      fiction: { scanlator_ids: [1], release: 'paused' }
    }

    assert_redirected_to fiction_path(@fiction)
    assert_nil @fiction.reload.paused_at
  end

  test 'update clears expected_chapters when the field is blank' do
    patch fiction_url(@fiction), params: {
      fiction: { scanlator_ids: [1], expected_chapters: '' }
    }

    assert_redirected_to fiction_path(@fiction)
    assert_nil @fiction.reload.expected_chapters
  end
end
