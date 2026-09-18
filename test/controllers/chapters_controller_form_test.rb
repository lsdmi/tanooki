# frozen_string_literal: true

require 'test_helper'

class ChaptersControllerFormTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
    @chapter = chapters(:one)
  end

  test 'new chapter form posts draft and publish intents' do
    get new_chapter_url(fiction: 'one')

    assert_select 'form[action=?][method=post]', chapters_path
    assert_select 'button[type=submit][name=intent][value=draft]', text: I18n.t('chapters.buttons.save')
    assert_select 'button[type=submit][name=intent][value=publish]', text: I18n.t('chapters.buttons.publish')
  end

  test 'new chapter form wires draft hotkey to save' do
    get new_chapter_url(fiction: 'one')

    assert_select '[data-controller~=draft-hotkey]'
    assert_select 'button[data-draft-hotkey-target=draftSubmit][value=draft]'
  end

  test 'new chapter form has no draft badge' do
    get new_chapter_url(fiction: 'one')

    assert_select 'h1', text: 'Додати Розділ'
    assert_select 'span', text: I18n.t('chapters.alerts.draft'), count: 0
  end

  test 'edit published chapter offers unpublish with confirm' do
    get edit_chapter_url(@chapter)

    assert_select 'button[name=intent][value=draft]', text: I18n.t('chapters.buttons.unpublish')
    assert_select 'button[name=intent][value=draft][data-turbo-confirm]'
    assert_select '[data-controller~=draft-hotkey]', count: 0
  end

  test 'edit draft chapter shows badge and save' do
    @chapter.update!(status: :draft, scanlator_ids: @chapter.scanlators.ids)
    get edit_chapter_url(@chapter)

    assert_select 'span', text: I18n.t('chapters.alerts.draft')
    assert_select 'button[type=submit][name=intent][value=draft]', text: I18n.t('chapters.buttons.save')
    assert_select 'button[data-draft-hotkey-target=draftSubmit]'
  end

  test 'edit scheduled chapter offers unpublish' do
    @chapter.update!(published_at: 2.days.from_now, scanlator_ids: @chapter.scanlators.ids)
    get edit_chapter_url(@chapter)

    assert_select 'button[name=intent][value=draft]', text: I18n.t('chapters.buttons.unpublish')
    assert_select 'span', text: I18n.t('chapters.alerts.draft'), count: 0
    assert_select 'p', text: I18n.t('chapters.hints.scheduled_vs_draft')
  end

  test 'edit live chapter does not prefill a past published_at as a schedule' do
    @chapter.published_at = 1.hour.ago
    @chapter.save(validate: false)
    get edit_chapter_url(@chapter)

    input = css_select('input#chapter_published_at_date').first

    assert input
    assert_predicate input['value'].to_s, :blank?
  end
end
