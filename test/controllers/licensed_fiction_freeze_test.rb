# frozen_string_literal: true

require 'test_helper'

class LicensedFictionFreezeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @fiction = fictions(:one)
    @chapter = chapters(:one)
    @editor = users(:user_two)
    ScanlatorUser.create!(user: @editor, scanlator: scanlators(:one))
    license!(2.days.ago)
    sign_in @editor
  end

  test 'the team cannot open the new chapter form' do
    get new_chapter_url(fiction: @fiction.slug)

    assert_redirected_to fiction_path(@fiction)
    assert_equal I18n.t('chapters.alerts.licensed'), flash[:alert]
  end

  test 'an admin cannot post a new chapter either' do
    sign_in users(:user_one)

    assert_no_difference 'Chapter.count' do
      post chapters_url, params: { chapter: { content: 'x' * 500, fiction_id: @fiction.id, number: 9,
                                              scanlator_ids: [1], title: 'Після ліцензії' } }
    end
    assert_redirected_to fiction_path(@fiction)
  end

  test 'the team cannot edit or update a released chapter' do
    get edit_chapter_url(@chapter)

    assert_redirected_to fiction_path(@fiction)
    patch chapter_url(@chapter), params: { chapter: { title: 'Змінено' } }

    assert_not_equal 'Змінено', @chapter.reload.title
  end

  test 'an admin can still open a released chapter for edit' do
    sign_in users(:user_one)

    get edit_chapter_url(@chapter)

    assert_response :success
  end

  test 'the team cannot delete a chapter' do
    delete reading_url(@chapter), as: :turbo_stream

    assert Chapter.exists?(@chapter.id)
    assert_includes response.body, I18n.t('chapters.alerts.licensed')
  end

  test 'the reader hides the edit link from the team' do
    get chapter_url(@chapter)

    assert_select 'a[href=?]', edit_chapter_path(@chapter), count: 0
  end

  test 'the studio list shows the licensed card without add or edit links' do
    get reading_url(@fiction)

    assert_select '#licensed-notice', text: /Ранобе ліцензовано.*лише перші 6 розділів/m
    assert_select 'a[href^=?]', '/chapters/new', count: 0
    assert_select 'a[title=?]', 'Редагувати', count: 0
  end

  test 'after the grace period the fiction edit page has the license block and nothing to save' do
    get edit_fiction_url(@fiction)

    assert_select '#fiction_license'
    assert_select 'input[name=?]', 'fiction[title]', count: 0
    assert_select 'input[type=submit]', count: 0
  end

  test 'within the grace period an update carries the license only' do
    license!(1.hour.ago)

    patch fiction_url(@fiction), params: { fiction: { title: 'Нова назва', licensed: '1',
                                                      license_publisher: 'Видавництво Тест' } }

    assert_redirected_to fiction_path(@fiction)
    assert_not_equal 'Нова назва', @fiction.reload.title
    assert_predicate @fiction, :licensed?
  end

  test 'the team cannot delete the fiction' do
    delete fiction_url(@fiction), as: :turbo_stream

    assert Fiction.exists?(@fiction.id)
    assert_includes response.body, I18n.t('fictions.license.frozen')
  end

  test 'the team cannot relabel the fiction through a listing nudge' do
    post mark_eighteen_fiction_listing_nudge_url(@fiction)

    assert_redirected_to fiction_path(@fiction)
    assert_equal 'everyone', @fiction.reload.content_rating
  end

  test 'an admin still gets the full fiction form' do
    sign_in users(:user_one)

    get edit_fiction_url(@fiction)

    assert_select 'input[name=?]', 'fiction[title]'
  end

  private

  def license!(at)
    @fiction.scanlator_ids = @fiction.scanlators.ids
    @fiction.update!(licensed_at: at, license_publisher: 'Видавництво Тест')
  end
end
