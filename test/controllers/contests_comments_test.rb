# frozen_string_literal: true

require 'test_helper'

class ContestsCommentsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
    @contest = contests(:results)
  end

  test 'show lists five comments and a button for the rest' do
    add_page_and_one_more

    get contest_path(@contest)

    assert_select '#discussion turbo-frame#comments article', count: Contests::CommentPage::PAGE_SIZE
    assert_select 'turbo-frame#comments_page_2 a[href=?]', comments_contest_path(@contest, page: 2),
                  text: 'Показати ще коментарі'
    assert_no_match(/Коментар 5/, response.body)
  end

  test 'the next comment page renders only its own frame' do
    add_page_and_one_more

    get comments_contest_path(@contest, page: 2)

    assert_select 'turbo-frame#comments_page_2', text: /Коментар 5/
    assert_select '#discussion', count: 0
  end

  private

  def add_page_and_one_more
    (Contests::CommentPage::PAGE_SIZE + 1).times do |index|
      @contest.comments.create!(user: users(:user_two), content: "Коментар #{index}", created_at: index.minutes.ago)
    end
  end
end
