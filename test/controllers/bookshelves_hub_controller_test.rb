# frozen_string_literal: true

require 'test_helper'

class BookshelvesHubControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user_one)
    @fiction = fictions(:one)
  end

  test 'index is public with focus and updates sections' do
    seed_hub_shelves!

    get bookshelves_url

    assert_response :success
    assert_select 'section[aria-label=?]', I18n.t('bookshelves.index.focus')
    assert_select 'section[aria-label=?]', I18n.t('bookshelves.index.updates')
  end

  test 'index title includes hub subtitle' do
    seed_hub_shelves!

    get bookshelves_url

    assert_select 'h1', text: /#{Regexp.escape(I18n.t('bookshelves.index.title'))}/
    assert_select 'h1 span', I18n.t('bookshelves.index.title_sub')
  end

  test 'index recent frame links escape to full page' do
    seed_hub_shelves!

    get bookshelves_url

    assert_select 'turbo-frame#hub-recent-page article a[href=?][data-turbo-frame=?]',
                  bookshelf_path(@recent_shelf), '_top'
    assert_select 'turbo-frame#hub-recent-page article a[href=?][data-turbo-frame=?]',
                  profile_path(@user.sqid), '_top'
  end

  test 'show breadcrumb links hub and current shelf' do
    bookshelf = bookshelves(:one)

    get bookshelf_url(bookshelf.sqid)

    assert_select 'nav[aria-label=?] a[href=?]',
                  I18n.t('bookshelves.show.breadcrumb_nav'),
                  bookshelves_path,
                  text: I18n.t('bookshelves.index.title')
    assert_select 'nav[aria-label=?] [aria-current=?]',
                  I18n.t('bookshelves.show.breadcrumb_nav'),
                  'page',
                  text: bookshelf.title
  end

  test 'fiction_options returns json for authenticated user' do
    sign_in @user
    get fiction_options_bookshelves_url(q: @fiction.title.first(3), as: :json)

    assert_response :success
    body = response.parsed_body

    assert(body.any? { |option| option['value'] == @fiction.id.to_s })
  end

  test 'fiction_options requires authentication' do
    get fiction_options_bookshelves_url(q: 'test', as: :json)

    assert_redirected_to new_user_session_url
  end

  test 'index recent turbo frame returns list partial' do
    seed_hub_shelves!

    get bookshelves_url, headers: { 'Turbo-Frame' => 'hub-recent-page' }

    assert_response :success
    assert_select 'turbo-frame#hub-recent-page'
    assert_select 'h1', count: 0
  end

  private

  def seed_hub_shelves!
    Bookshelves::HubPreview::POPULAR_LIMIT.times { |index| create_hub_shelf!("Hub popular seed #{index}", 10_000 - index) }
    @recent_shelf = create_hub_shelf!('Hub recent seed', 1)
    @recent_shelf.update!(updated_at: 1.second.from_now)
  end

  def create_hub_shelf!(title, views)
    shelf = @user.bookshelves.create!(
      title:,
      description: 'Seeded hub shelf for controller tests',
      fiction_ids: [@fiction.id],
      views:
    )
    Bookshelves::SyncFictions.call(bookshelf: shelf, fiction_ids: [@fiction.id])
    pad_hub_shelf!(shelf, title:)
    shelf
  end

  def pad_hub_shelf!(shelf, title:)
    while shelf.bookshelf_fictions.count < Bookshelves::HubScope::MIN_FICTIONS
      clone = @fiction.dup
      clone.title = "#{title} work #{shelf.bookshelf_fictions.count}"
      clone.slug = nil
      clone.save!(validate: false)
      BookshelfFiction.create!(bookshelf: shelf, fiction: clone)
    end
  end
end
