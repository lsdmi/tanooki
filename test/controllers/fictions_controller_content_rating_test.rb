# frozen_string_literal: true

require 'test_helper'

class FictionsControllerContentRatingTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
    @fiction = fictions(:one)
  end

  test 'new form defaults to everyone with the matching hint' do
    get new_fiction_url

    assert_response :success
    assert_content_rating_radios(checked: 'everyone')
    assert_select 'input[name="fiction[adult_content]"]', count: 0
  end

  test 'edit form checks the stored band' do
    @fiction.update!(content_rating: :sixteen)

    get edit_fiction_url(@fiction)

    assert_response :success
    assert_content_rating_radios(checked: 'sixteen')
    assert_select 'input[name="fiction[content_rating]"][value=everyone]:not([checked])'
  end

  test 'update persists each content rating band' do
    %w[sixteen eighteen everyone].each do |band|
      patch fiction_url(@fiction), params: {
        fiction: { scanlator_ids: [1], content_rating: band }
      }

      assert_redirected_to fiction_path(@fiction)
      assert_equal band, @fiction.reload.content_rating
    end
  end

  test 'create persists the chosen content rating' do
    assert_difference('Fiction.count') do
      post fictions_url, params: {
        fiction: {
          title: 'Rated Sixteen',
          author: 'New Author',
          description: 'a' * 50,
          cover: valid_cover_upload,
          scanlator_ids: [1],
          content_rating: 'sixteen'
        }
      }
    end

    fiction = Fiction.find_by!(slug: 'rated-sixteen')

    assert_predicate fiction, :content_rating_sixteen?
    assert_not fiction.age_gated?
  end

  test 'ignores the retired adult_content param' do
    @fiction.update!(content_rating: :sixteen)

    patch fiction_url(@fiction), params: {
      fiction: { scanlator_ids: [1], adult_content: '1', title: @fiction.title }
    }

    assert_redirected_to fiction_path(@fiction)
    assert_predicate @fiction.reload, :content_rating_sixteen?
  end

  test 'sixteen show page is not age gated and shows amber pill' do
    @fiction.update!(content_rating: :sixteen)
    get fiction_url(@fiction)

    assert_response :success
    assert_includes response.body, I18n.t('fictions.age_rating_notice.sixteen.title')
    assert_select 'span.bg-amber-200', text: '16+'
  end

  test 'sixteen show notice skips the adult disclaimer hook' do
    @fiction.update!(content_rating: :sixteen)
    get fiction_url(@fiction)

    assert_select '[data-age-rating-notice-rating-value=sixteen]'
    assert_no_match I18n.t('fictions.age_rating_notice.eighteen.title'), response.body
  end

  test 'eighteen show page keeps the gate and rose pill' do
    @fiction.update!(content_rating: :eighteen)
    get fiction_url(@fiction)

    assert_includes response.body, I18n.t('fictions.age_rating_notice.eighteen.title')
    assert_select 'span.bg-rose-200', text: '18+'
    assert_select 'section.adult-content-disclaimer'
  end

  test 'sixteen chapter shows notice without locking the body' do
    chapter = chapters(:one)
    chapter.fiction.update!(content_rating: :sixteen)

    get chapter_url(chapter)

    assert_includes response.body, I18n.t('fictions.age_rating_notice.sixteen.title')
    assert_not_includes response.body, 'adult-content-gate--locked'
    assert_not_includes response.body, 'adult-content-disclaimer'
  end

  private

  def content_rating_hint_payload
    raw = css_select('[data-content-rating-hint-hints-value]').first['data-content-rating-hint-hints-value']
    JSON.parse(raw)
  end

  def assert_content_rating_radios(checked:)
    assert_select 'legend', text: I18n.t('fictions.form.content_rating.legend')
    assert_select "input[name='fiction[content_rating]'][value=#{checked}][checked]"
    assert_select '#fiction_content_rating_hint', text: I18n.t("fictions.form.content_rating.hints.#{checked}")
    assert_equal I18n.t('fictions.form.content_rating.hints.sixteen'), content_rating_hint_payload['sixteen']
    Fiction.content_ratings.each_key do |band|
      assert_select "input[type=radio][name='fiction[content_rating]'][value=#{band}]"
      assert_select 'span', text: I18n.t("fictions.form.content_rating.labels.#{band}")
    end
  end
end
