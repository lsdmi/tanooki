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

  test 'edit form shows complete checkbox unchecked by default' do
    get edit_fiction_url(@fiction)

    assert_select 'label', text: 'Переклад на Баці завершено'
    assert_select 'input[name="fiction[complete]"][type=checkbox]:not([checked])'
  end

  test 'edit form prechecks complete when completed_at is set' do
    @fiction.update!(completed_at: Time.current)

    get edit_fiction_url(@fiction)

    assert_select 'input[name="fiction[complete]"][type=checkbox][checked]'
  end

  test 'update stamps completed_at from the complete checkbox' do
    patch fiction_url(@fiction), params: {
      fiction: { scanlator_ids: [1], complete: '1' }
    }

    assert_redirected_to fiction_path(@fiction)
    assert_not_nil @fiction.reload.completed_at
  end

  test 'update clears expected_chapters when the field is blank' do
    patch fiction_url(@fiction), params: {
      fiction: { scanlator_ids: [1], expected_chapters: '' }
    }

    assert_redirected_to fiction_path(@fiction)
    assert_nil @fiction.reload.expected_chapters
  end
end
