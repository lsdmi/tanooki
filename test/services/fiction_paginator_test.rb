# frozen_string_literal: true

require 'test_helper'
require 'pagy'

class FictionPaginatorTest < ActiveSupport::TestCase
  def setup
    @fictions = [
      fictions(:one),
      fictions(:two)
    ]
    @params = {
      'chapter_page_fiction-1' => 2,
      'chapter_page_fiction-2' => 1
    }
    @user = users(:user_one)
    @pagy = Pagy.new(count: 20, page: 1, items: 10)
    @paginator = FictionPaginator.new(@pagy, @fictions, @params, @user)
  end

  def test_call_method
    @paginator.call

    test_size
    test_instances
    test_content
    test_pagy_variables_fiction_one
    test_pagy_variables_fiction_two
  end

  private

  def test_size
    assert_equal 2, @paginator.initiate.size
  end

  def test_instances
    assert_instance_of Array, @paginator.initiate['one'][:paginated_chapters]
    assert_instance_of Fiction, @paginator.initiate['two'][:fictions]
    assert_instance_of Array, @paginator.initiate['two'][:paginated_chapters]
    assert_instance_of Fiction, @paginator.initiate['two'][:fictions]
  end

  def test_content
    assert_equal @fictions[0].chapters.order(number: :desc), @paginator.initiate['one'][:paginated_chapters].second
    assert_equal @fictions[1].chapters.order(number: :desc), @paginator.initiate['two'][:paginated_chapters].second
  end

  def test_pagy_variables_fiction_one
    assert_equal 1, @paginator.initiate['one'][:paginated_chapters].first.page
    assert_equal 8, @paginator.initiate['one'][:paginated_chapters].first.items
  end

  def test_pagy_variables_fiction_two
    assert_equal 1, @paginator.initiate['two'][:paginated_chapters].first.page
    assert_equal 8, @paginator.initiate['two'][:paginated_chapters].first.items
  end
end
