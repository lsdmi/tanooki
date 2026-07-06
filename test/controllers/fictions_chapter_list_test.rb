# frozen_string_literal: true

require 'test_helper'

class FictionsChapterListTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @fiction = fictions(:one)
    sign_in users(:user_one)
  end

  test 'show preloads first section chapters inline' do
    get fiction_url(@fiction)

    assert_response :success
    assert_select '#chapters-list ul li', minimum: 1
    assert_select '#chapters-list .chapter-section-placeholder', count: 0
  end

  test 'show lazy loads later accordion sections' do
    vol1, vol2 = create_volume_pair_chapters(@fiction)

    get fiction_url(@fiction)

    assert_response :success
    assert_select '[data-chapter-section-url]', count: 2
  ensure
    vol2&.destroy
    vol1&.destroy
  end

  test 'legacy toggle_order collection URL no longer collides with fiction show' do
    chapter = chapters(:one)

    get "/fictions/toggle_order?current_chapter_id=#{chapter.id}&id=#{@fiction.slug}&order=desc&reader_drawer=true"

    assert_response :not_found
  end

  test 'toggle_order reverses section headers' do
    vol1, vol2 = create_volume_pair_chapters(@fiction)

    get fiction_url(@fiction)

    assert_operator response.body.index('Том 2'), :<, response.body.index('Том 1')

    post toggle_order_fiction_path(@fiction, order: :desc),
         headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

    assert_response :success
    assert_operator response.body.index('Том 1'), :<, response.body.index('Том 2')
  ensure
    vol2&.destroy
    vol1&.destroy
  end

  test 'guest chapter list excludes chapters not yet public' do
    sign_out :user

    travel_to Time.zone.parse('2026-06-01 12:00') do
      update_chapter_schedule!(chapters(:one), published_at: 1.day.from_now)

      get fiction_url(@fiction)

      assert_response :success
      assert_select '#chapters-list a[href=?]', chapter_path(chapters(:one)), count: 0
      assert_select '#chapters-list a[href=?]', chapter_path(chapters(:two))
    ensure
      update_chapter_schedule!(chapters(:one), published_at: nil)
    end
  end

  test 'show renders epub download on section header when allowed' do
    get fiction_url(@fiction)

    assert_response :success
    assert_select '#sort-chapters [data-controller="epub-download"]'
  end

  test 'show omits epub download when scanlator is not convertable' do
    scanlators(:one).update!(convertable: false)

    get fiction_url(@fiction)

    assert_select '#sort-chapters [data-controller="epub-download"]', count: 0
  ensure
    scanlators(:one).update!(convertable: true)
  end

  private

  def create_volume_pair_chapters(fiction)
    [create_volume_chapter(fiction, 1, 'Vol 1'), create_volume_chapter(fiction, 2, 'Vol 2')]
  end

  def create_volume_chapter(fiction, volume_number, title, number: 1)
    Chapter.create!(
      fiction: fiction,
      user: users(:user_one),
      title: title,
      number: number,
      volume_number: volume_number,
      content: 'x' * 500,
      scanlator_ids: [scanlators(:one).id]
    )
  end

  def update_chapter_schedule!(chapter, published_at:)
    chapter.update!(published_at:, scanlator_ids: chapter.scanlators.ids)
  end
end
