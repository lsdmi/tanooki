# frozen_string_literal: true

require 'test_helper'

class BookshelvesHubVisibilityTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user_one)
    @fiction = fictions(:one)
  end

  test 'index hides another reader shelf when filter leaves too few visible works' do
    other = users(:user_two)
    eighteen = fictions(:eighteen)
    shelf = other.bookshelves.create!(
      title: 'Hub filtered empty shelf',
      description: 'Only 18+ works so a capped reader should not see this row',
      fiction_ids: [eighteen.id],
      views: 50_000
    )
    fill_shelf!(shelf, with: eighteen, count: Bookshelves::HubScope::MIN_FICTIONS)

    sign_in @user
    get bookshelves_url

    assert_response :success
    assert_select 'a[href=?]', bookshelf_path(shelf), count: 0
  end

  test 'index hides shelves below the minimum fiction count' do
    thin = @user.bookshelves.create!(
      title: 'Hub thin shelf xx',
      description: 'Two works only so the public hub should omit this shelf',
      fiction_ids: [@fiction.id],
      views: 99_000
    )
    fill_shelf!(thin, with: @fiction, count: 2)

    get bookshelves_url

    assert_response :success
    assert_select 'a[href=?]', bookshelf_path(thin), count: 0
  end

  private

  def fill_shelf!(shelf, with:, count:)
    BookshelfFiction.where(bookshelf: shelf).delete_all
    count.times { |index| add_shelf_fiction!(shelf, with, index) }
  end

  def add_shelf_fiction!(shelf, source, index)
    fiction = source
    if index.positive?
      fiction = source.dup
      fiction.title = "#{shelf.title} work #{index}"
      fiction.slug = nil
      fiction.save!(validate: false)
    end
    BookshelfFiction.create!(bookshelf: shelf, fiction:)
  end
end
