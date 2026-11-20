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

  test 'new publication cover drop zone accepts drops and has no click-open action' do
    get new_publication_path

    assert_select '[data-action*="drop->dropzone#drop"]'
    assert_select '[data-action*="click->dropzone#open"]', count: 0
    assert_select 'img[data-dropzone-target=preview].hidden, [data-dropzone-target=name].hidden', count: 2
  end

  test 'new publication cover file input covers the box without hiding it' do
    get new_publication_path

    cover = css_select('input#publication_cover[type=file][aria-label][data-dropzone-target=input]').sole

    assert_includes cover['class'].split, 'opacity-5'
    assert_not_includes cover['class'].split, 'opacity-0'
    assert_select 'input#publication_cover.sr-only, input#publication_cover.hidden', count: 0
  end

  test 'edit publication shows the saved cover in the dropzone' do
    get edit_publication_path(@publication)

    preview = css_select('img[data-dropzone-target=preview]').sole

    assert_match 'active_storage', preview['src']
    assert_not_includes preview['class'].to_s.split, 'hidden'
    assert_select '#image_name', text: 'blob_one.png'
  end

  test 'unprocessable publish still loads slimselect assets' do
    post publications_url, params: {
      intent: 'publish',
      publication: {
        type: 'Tale',
        title: 'Too short',
        description: 'short'
      }
    }

    assert_response :unprocessable_content
    assert_select 'link[href*="slimselect"][data-turbo-track="reload"]'
    assert_select 'select[data-controller="slim"]'
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
