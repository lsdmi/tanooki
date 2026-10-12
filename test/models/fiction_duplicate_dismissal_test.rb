# frozen_string_literal: true

require 'test_helper'

class FictionDuplicateDismissalTest < ActiveSupport::TestCase
  test 'stores each pair once, smaller id first' do
    third = Fiction.new(slug: 'dismiss-third', title: 'Third', author: 'Автор', description: 'd' * 30)
    third.save!(validate: false)
    FictionDuplicateDismissal.dismiss([fictions(:two), fictions(:one), third], user: users(:user_one))
    FictionDuplicateDismissal.dismiss([fictions(:one), fictions(:two)], user: users(:user_two))

    pairs = FictionDuplicateDismissal.order(:fiction_id, :other_fiction_id).pluck(:fiction_id, :other_fiction_id)

    assert_equal [[1, 2], [1, third.id], [2, third.id]], pairs
    assert_equal users(:user_one), FictionDuplicateDismissal.find_by(fiction_id: 1, other_fiction_id: 2).user
  end
end
