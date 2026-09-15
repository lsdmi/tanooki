# frozen_string_literal: true

require 'test_helper'

class PublicationsControllerFormTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
    @publication = publications(:tale_approved_one)
  end

  test 'new publication form posts draft and publish intents' do
    get new_publication_path

    assert_select 'form[action=?][method=post]', publications_path
    assert_select 'button[type=submit][name=intent][value=draft]', text: I18n.t('chapters.buttons.save')
    assert_select 'button[type=submit][name=intent][value=publish]', text: I18n.t('publications.buttons.publish')
  end

  test 'new publication form wires draft hotkey to save' do
    get new_publication_path

    assert_select '[data-controller~=draft-hotkey]'
    assert_select 'button[data-draft-hotkey-target=draftSubmit][value=draft]'
  end

  test 'new publication form has no draft badge' do
    get new_publication_path

    assert_select 'h1', text: 'Створити Допис'
    assert_select 'span', text: I18n.t('chapters.alerts.draft'), count: 0
  end

  test 'edit published publication offers unpublish with confirm' do
    get edit_publication_path(@publication)

    assert_select 'button[name=intent][value=draft]', text: I18n.t('chapters.buttons.unpublish')
    assert_select 'button[name=intent][value=draft][data-turbo-confirm]'
    assert_select '[data-controller~=draft-hotkey]', count: 0
  end

  test 'edit draft publication shows badge and save' do
    @publication.update!(status: :draft)
    get edit_publication_path(@publication)

    assert_select 'span', text: I18n.t('chapters.alerts.draft')
    assert_select 'button[type=submit][name=intent][value=draft]', text: I18n.t('chapters.buttons.save')
    assert_select 'button[data-draft-hotkey-target=draftSubmit]'
  end
end
