# frozen_string_literal: true

require 'test_helper'

class UserProfileBookshelvesTest < ActiveSupport::TestCase
  test 'profile featured bookshelves stays capped at one' do
    user = users(:user_one)
    one = bookshelves(:one)
    one.fiction_ids = one.fictions.pluck(:id)
    one.update!(views: 1)

    shelf = Bookshelf.new(
      user:,
      title: 'Second featured shelf',
      description: 'Long enough description for the bookshelf validation.',
      views: 99
    )
    shelf.fiction_ids = [fictions(:one).id]
    shelf.save!
    BookshelfFiction.create!(bookshelf: shelf, fiction: fictions(:one))

    featured = user.profile_featured_bookshelves.to_a

    assert_equal 1, featured.size
    assert_equal 99, featured.first.views
    assert_predicate featured.first.fictions, :any?
  end
end
