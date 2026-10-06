# frozen_string_literal: true

require 'test_helper'

# P3 «done when» on a «Маг на повну ставку»-sized list: chapters 1–1999 plus 447.99, 20 range groups.
class FictionsHeavyChapterListTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  OPEN_PAGER = '#chapters-list .accordion-content:not(.hidden) [data-controller="chapter-group-pager"]'

  setup do
    @user = users(:user_one)
    @fiction = fictions(:one)
    ReadingChapterRead.where(user: @user).delete_all
    insert_chapters((3..1999).map(&:to_s) + ['447.99'])
  end

  test 'the list has no inner scroll and pages the newest group' do
    get fiction_url(@fiction)

    assert_select '#chapters-list [class*="max-h-"], #chapters-list [class*="overflow-y-auto"]', count: 0
    assert_select '#chapters-list .accordion', count: 20
    assert_select "#{OPEN_PAGER}[data-chapter-group-pager-url-value*='section=r-1901-2000'] > ul > li", count: 20
  end

  test 'a reader opens the continue group rendered through the row' do
    resume_at(1612)
    sign_in @user
    get fiction_url(@fiction)

    assert_select "#{OPEN_PAGER}[data-chapter-group-pager-url-value*='section=r-1601-1700'] > ul > li", count: 90
    assert_select "[data-chapter-jump-target='chip']", text: /До поточного розділу · 1612/
  end

  test 'jumps reach 1612 and 447.99, and 5000 is an inline error' do
    jumps = [1612, '447.99', 5000].map do |number|
      get chapter_jump_fiction_url(@fiction, order: :desc, number:)
      response.parsed_body.values_at('section_key', 'target_index', 'error')
    end

    assert_equal ['r-1601-1700', 9, nil], jumps[0]
    assert_equal ['r-401-500', 9, nil], jumps[1]
    assert_equal [nil, nil, 'Розділу 5000 немає · доступні 1–1999'], jumps[2]
  end

  test '«Показати ще» and «Показати всі» page through a full group' do
    pages = [20, 'all'].map do |limit|
      get chapter_section_fiction_url(@fiction, section: 'r-1801-1900', order: :desc, offset: 20, limit:)
      Nokogiri::HTML.fragment(response.body).css('li').size
    end

    assert_equal [20, 80], pages
  end

  private

  # One INSERT: 2000 `Chapter.create!` calls with rich-text content would take seconds.
  def insert_chapters(numbers)
    connection = Chapter.connection
    published_at = connection.quote(1.day.ago)
    now = connection.quote(Time.current)
    values = numbers.map do |number|
      "(#{@fiction.id}, #{@user.id}, #{number}, #{connection.quote("Chapter #{number}")}, " \
        "#{connection.quote("heavy-#{number}")}, 'published', #{published_at}, #{now}, #{now})"
    end
    connection.execute('INSERT INTO chapters (fiction_id, user_id, number, title, slug, status, published_at, ' \
                       "created_at, updated_at) VALUES #{values.join(', ')}")
  end

  def resume_at(number)
    chapter = @fiction.chapters.find_by!(number:)
    reading_progresses(:one).update!(chapter:, resume_at: Time.current, status: :active)
  end
end
