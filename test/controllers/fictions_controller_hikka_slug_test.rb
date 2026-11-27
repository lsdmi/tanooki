# frozen_string_literal: true

require 'test_helper'

class FictionsControllerHikkaSlugTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  LINK = 'https://hikka.io/novel/guimi-zhi-zhu-7059fd/'
  SLUG = 'guimi-zhi-zhu-7059fd'

  setup do
    FakeHikkaLookup.reset!
    @fiction = fictions(:one)
    sign_in users(:user_one)
  end

  test 'edit form shows the Hikka field with the saved slug' do
    @fiction.update_column(:hikka_slug, SLUG)

    get edit_fiction_url(@fiction)

    assert_select 'label', text: 'Тайтл на Хіці'
    assert_select 'input[name="fiction[hikka_slug]"][value=?]', SLUG
  end

  test 'an admin saves a pasted Hikka link as the bare slug' do
    with_hikka(:found) { patch fiction_url(@fiction), params: { fiction: { scanlator_ids: [1], hikka_slug: LINK } } }

    assert_redirected_to fiction_path(@fiction)
    assert_equal SLUG, @fiction.reload.hikka_slug
  end

  test 'a team member saves the Hikka slug' do
    ScanlatorUser.create!(user: users(:user_two), scanlator: scanlators(:one))
    sign_in users(:user_two)

    with_hikka(:found) { patch fiction_url(@fiction), params: { fiction: { scanlator_ids: [1], hikka_slug: SLUG } } }

    assert_equal SLUG, @fiction.reload.hikka_slug
  end

  test 'a user outside the team cannot set the Hikka slug' do
    sign_in users(:user_two)

    with_hikka(:found) { patch fiction_url(@fiction), params: { fiction: { scanlator_ids: [1], hikka_slug: SLUG } } }

    assert_redirected_to root_path
    assert_nil @fiction.reload.hikka_slug
  end

  test 'an empty field clears the Hikka slug' do
    @fiction.update_column(:hikka_slug, SLUG)

    patch fiction_url(@fiction), params: { fiction: { scanlator_ids: [1], hikka_slug: '' } }

    assert_nil @fiction.reload.hikka_slug
  end

  test 'a slug Hikka does not know re-renders the form with the error' do
    with_hikka(:not_found) do
      patch fiction_url(@fiction), params: { fiction: { scanlator_ids: [1], hikka_slug: SLUG } }
    end

    assert_response :unprocessable_content
    assert_select 'p', text: I18n.t('activerecord.errors.models.fiction.attributes.hikka_slug.not_found_on_hikka')
    assert_nil @fiction.reload.hikka_slug
  end

  test 'a slug another fiction already holds re-renders the form with the error' do
    fictions(:two).update_column(:hikka_slug, SLUG)

    with_hikka(:found) { patch fiction_url(@fiction), params: { fiction: { scanlator_ids: [1], hikka_slug: SLUG } } }

    assert_response :unprocessable_content
    assert_select 'p', text: I18n.t('activerecord.errors.models.fiction.attributes.hikka_slug.taken')
    assert_nil @fiction.reload.hikka_slug
  end

  test 'a slug taken by another save between validation and write re-renders the form with the error' do
    claim = lambda do
      fictions(:two).update_column(:hikka_slug, SLUG)
      :found
    end

    with_hikka(claim) { patch fiction_url(@fiction), params: { fiction: { scanlator_ids: [1], hikka_slug: SLUG } } }

    assert_response :unprocessable_content
    assert_select 'p', text: I18n.t('activerecord.errors.models.fiction.attributes.hikka_slug.taken')
    assert_nil @fiction.reload.hikka_slug
  end

  test 'an unreachable Hikka saves the fiction and shows a warning' do
    with_hikka(:unavailable) do
      patch fiction_url(@fiction), params: { fiction: { scanlator_ids: [1], hikka_slug: SLUG } }
    end

    assert_redirected_to fiction_path(@fiction)
    assert_equal SLUG, @fiction.reload.hikka_slug
    assert_equal I18n.t('fictions.form.hikka_slug.unavailable'), flash[:alert]
  end

  test 'a frozen licensed fiction ignores the Hikka slug' do
    @fiction.update!(licensed_at: 2.days.ago, license_publisher: 'Видавництво')
    ScanlatorUser.create!(user: users(:user_two), scanlator: scanlators(:one))
    sign_in users(:user_two)

    with_hikka(:found) do
      patch fiction_url(@fiction),
            params: { fiction: { licensed: '1', license_publisher: 'Видавництво', hikka_slug: SLUG } }
    end

    assert_nil @fiction.reload.hikka_slug
  end

  private

  def with_hikka(result, &)
    FakeHikkaLookup.result = result
    Fictions::HikkaLookup.stub(:new, ->(slug) { FakeHikkaLookup.new(slug) }, &)
  end
end
