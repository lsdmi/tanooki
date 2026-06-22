# frozen_string_literal: true

require 'test_helper'

class TurboFlashStreamIntegrationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'publication destroy turbo stream sets layout notice' do
    sign_in users(:user_one)
    publication = publications(:tale_created_one)

    delete publication_url(publication), as: :turbo_stream

    assert_turbo_stream_flash_notice(I18n.t('publications.notices.destroy_success'))
  end

  test 'publication destroy turbo stream refreshes publications list' do
    sign_in users(:user_one)
    publication = publications(:tale_created_one)

    delete publication_url(publication), as: :turbo_stream

    assert_select 'turbo-stream[action="update"][target="publications-list"]'
  end

  test 'bookshelf destroy turbo stream sets layout notice' do
    sign_in users(:user_one)
    bookshelf = bookshelves(:one)

    delete bookshelf_url(bookshelf.sqid), as: :turbo_stream

    assert_turbo_stream_flash_notice(I18n.t('bookshelves.notices.destroy_success'))
  end

  test 'bookshelf destroy turbo stream refreshes bookshelves list' do
    sign_in users(:user_one)
    bookshelf = bookshelves(:one)

    delete bookshelf_url(bookshelf.sqid), as: :turbo_stream

    assert_select 'turbo-stream[action="update"][target="bookshelves-list"]'
  end
end
