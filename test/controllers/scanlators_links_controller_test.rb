# frozen_string_literal: true

require 'test_helper'

class ScanlatorsLinksControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
    @scanlator = scanlators(:one)
  end

  test 'update explains why a donation link outside known services is rejected' do
    patch scanlator_url(@scanlator), params: {
      scanlator: { member_ids: [users(:user_one).id], bank_url: 'https://t.me/c/1614732671/498' }
    }

    assert_response :unprocessable_content
    assert_select 'p', text: /Посилання на банку має вести на monobank, .* або Patreon/
    assert_nil @scanlator.reload.bank_url
  end

  test 'update saves a monobank jar typed without a scheme' do
    patch scanlator_url(@scanlator), params: {
      scanlator: { member_ids: [users(:user_one).id], bank_url: 'send.monobank.ua/jar/abc' }
    }

    assert_redirected_to scanlator_path(@scanlator)
    assert_equal 'https://send.monobank.ua/jar/abc', @scanlator.reload.bank_url
  end

  test 'team page shows the donation button with the service name' do
    @scanlator.update!(bank_url: 'https://send.monobank.ua/jar/abc')

    get scanlator_url(@scanlator)

    assert_select 'a[href="https://send.monobank.ua/jar/abc"][aria-label="Підтримати через monobank"]'
  end
end
