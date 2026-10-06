# frozen_string_literal: true

require 'test_helper'

class FictionsChapterJumpTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user_one)
    @fiction = fictions(:one)
    (101..135).each do |number|
      Chapter.create!(fiction: @fiction, user: @user, title: "Chapter #{number}", number:, content: 'x' * 500,
                      scanlator_ids: [scanlators(:one).id])
    end
  end

  test 'the Chapters tab has the jump field for the current sort' do
    get fiction_url(@fiction)

    assert_select '#chapter-jump-input[placeholder="Перейти до розділу…"]'
    assert_select "[data-controller='chapter-jump'][data-chapter-jump-url-value*='order=desc']"
  end

  test 'a jump returns the group and a window of rows around the chapter' do
    get chapter_jump_fiction_url(@fiction, order: :asc, number: '120')
    body = response.parsed_body

    assert_equal ['r-101-200', 9], [body['section_key'], body['target_index']]
    assert_includes body['html'], 'data-chapter-group-pager-start-value="10"'
    assert_includes body['html'], 'Показати 101–110'
  end

  test 'a jump window is shown whole on phones' do
    get chapter_jump_fiction_url(@fiction, order: :desc, number: '120')
    html = Nokogiri::HTML.fragment(response.parsed_body['html'])

    assert_equal 20, html.css('[data-chapter-group-pager-target="list"] > li').size
    assert_empty html.css('[data-chapter-group-pager-target="list"][class*="nth-child"]')
  end

  test 'a missing or malformed number gets an inline error' do
    get chapter_jump_fiction_url(@fiction, order: :asc, number: '500')

    assert_equal 'Розділу 500 немає · доступні 1–135', response.parsed_body['error']

    get chapter_jump_fiction_url(@fiction, order: :asc, number: 'abc')

    assert_equal 'Введіть номер розділу, наприклад 86', response.parsed_body['error']
  end

  test 'a reader gets rows with their progress' do
    sign_in @user
    get chapter_jump_fiction_url(@fiction, order: :asc, number: '2')
    html = Nokogiri::HTML.fragment(response.parsed_body['html'])

    assert_equal ['r-1-100', 1], response.parsed_body.values_at('section_key', 'target_index')
    assert_equal "chapter_list_chapter_#{chapters(:two).id}", html.css('li')[1]['id']
  end

  test 'a reader with a continue chapter gets the chip back to it' do
    ReadingChapterRead.where(user: @user).delete_all
    reading_progresses(:one).update!(chapter: chapters(:two), resume_at: Time.current, status: :active)
    sign_in @user
    get fiction_url(@fiction)

    assert_select "[data-chapter-jump-continue-id-value='#{chapters(:two).id}']" \
                  "[data-chapter-jump-continue-section-value='r-1-100']"
    assert_select "[data-chapter-jump-target='chip'][hidden]", text: /До поточного розділу · 2/
  end

  test 'guests get sticky group headers and no chip' do
    get fiction_url(@fiction)

    assert_select "[data-chapter-jump-target='chip']", count: 0
    assert_select '#chapters-list .accordion.overflow-clip > .accordion-header.sticky', count: 2
  end

  test 'the chip asks for its chapter by id' do
    sign_in @user
    get chapter_jump_fiction_url(@fiction, order: :desc, chapter_id: chapters(:one).id)

    assert_equal ['r-1-100', 1], response.parsed_body.values_at('section_key', 'target_index')
  end
end
