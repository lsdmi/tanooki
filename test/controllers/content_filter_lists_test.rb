# frozen_string_literal: true

require 'test_helper'

class ContentFilterListsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @eighteen = fictions(:eighteen)
    @everyone = fictions(:one)
    @sixteen = fictions(:two)
  end

  test 'the all-updates calendar hides a capped release and subscriptions keep it' do
    sign_in users(:user_one)
    users(:user_one).content_filter.update!(max_content_rating: 0)

    get calendar_fictions_path

    assert_select '.event-card a', text: /\A#{Regexp.escape(@sixteen.title)}\z/, count: 0
    assert_includes response.body, I18n.t('content_filters.hidden_count', count: 1)

    get calendar_fictions_path(subscriptions: true)

    assert_select '.event-card a', text: /\A#{Regexp.escape(@sixteen.title)}\z/
  end

  test 'another reader shelf hides 18+ and says how many' do
    sign_in users(:user_one)
    BookshelfFiction.create!(bookshelf: bookshelves(:two), fiction: @everyone)
    BookshelfFiction.create!(bookshelf: bookshelves(:two), fiction: @eighteen)

    get bookshelf_url(bookshelves(:two).sqid)

    assert_select '#fiction-list-page [data-fiction-picker-id-param=?]', @eighteen.id.to_s, count: 0
    assert_select '#fiction-list-page [data-fiction-picker-id-param=?]', @everyone.id.to_s
    assert_includes response.body, I18n.t('content_filters.hidden_count', count: 1)
  end

  test 'the owner still sees 18+ on their own shelf' do
    sign_in users(:user_one)
    BookshelfFiction.create!(bookshelf: bookshelves(:one), fiction: @eighteen)

    get bookshelf_url(bookshelves(:one).sqid)

    assert_select '#fiction-list-page [data-fiction-picker-id-param=?]', @eighteen.id.to_s
    assert_not_includes response.body, I18n.t('content_filters.hidden_count', count: 1)
  end

  test 'a hidden genre page shows its works and a notice' do
    sign_in users(:user_two)
    FictionGenre.create!(fiction: @everyone, genre: genres(:bl))

    get fiction_genre_fictions_url(genres(:bl).slug)

    assert_includes response.body, @everyone.title
    assert_includes response.body, I18n.t('content_filters.genre_hidden')
  end

  test 'a genre page still hides 18+ when the genre itself is not hidden' do
    sign_in users(:user_one)
    FictionGenre.create!(fiction: @everyone, genre: genres(:three))
    FictionGenre.create!(fiction: @eighteen, genre: genres(:three))
    release_eighteen

    get fiction_genre_fictions_url(genres(:three).slug)

    assert_select "a[href='#{fiction_path(@everyone)}']"
    assert_select "a[href='#{fiction_path(@eighteen)}']", count: 0
  end

  test 'hot novelty details omit a fiction the reader hid' do
    sign_in users(:user_one)

    get details_fiction_url(@eighteen, variant: 'hot_novelty', format: :turbo_stream)

    assert_response :success
    assert_not_includes response.body, @eighteen.title
  end

  private

  def release_eighteen
    Chapter.create!(
      fiction: @eighteen,
      user: users(:user_one),
      title: 'Eighteen drop',
      number: 1,
      content: 'x' * 500,
      scanlator_ids: [scanlators(:one).id]
    )
  end
end
