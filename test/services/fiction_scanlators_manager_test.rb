# frozen_string_literal: true

require 'test_helper'

class FictionScanlatorsManagerTest < ActiveSupport::TestCase
  setup do
    @fiction = fictions(:one)
    @scanlator_one = scanlators(:one)
    @scanlator_two = scanlators(:two)
    FictionScanlator.find_or_create_by!(fiction: @fiction, scanlator: @scanlator_two)
  end

  test 'non-admin save keeps scanlator teams not listed in the form' do
    user = users(:user_two)

    FictionScanlatorsManager.new([@scanlator_two.id.to_s], @fiction, user: user).operate

    assert_equal [@scanlator_one.id, @scanlator_two.id].sort, @fiction.scanlators.ids.sort
  end

  test 'non-admin can remove only their own team from the fiction' do
    user = users(:user_two)

    FictionScanlatorsManager.new([], @fiction, user: user).operate

    assert_equal [@scanlator_one.id], @fiction.scanlators.ids
  end

  test 'admin save replaces the full scanlator list' do
    admin = users(:user_one)

    FictionScanlatorsManager.new([@scanlator_two.id.to_s], @fiction, user: admin).operate

    assert_equal [@scanlator_two.id], @fiction.scanlators.ids
  end
end
