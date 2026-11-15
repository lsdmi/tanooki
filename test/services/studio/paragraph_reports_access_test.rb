# frozen_string_literal: true

require 'test_helper'

module Studio
  class ParagraphReportsAccessTest < ActiveSupport::TestCase
    test 'admins can always open the tab' do
      assert ParagraphReportsAccess.allowed?(users(:user_one))
    end

    test 'a reader without a team cannot open the tab' do
      reader = users(:user_two)
      reader.scanlator_users.destroy_all

      assert_not ParagraphReportsAccess.allowed?(reader)
    end

    test 'a team member without fictions cannot open the tab' do
      # scanlator :two has a member but no fictions in fixtures
      member = users(:user_two)

      assert_predicate member.scanlators, :any?
      assert_not member.fictions.exists?
      assert_not ParagraphReportsAccess.allowed?(member)
    end

    test 'a team member with fictions can open the tab' do
      member = users(:user_one)
      member.update!(admin: false)

      assert_predicate member.scanlators, :any?
      assert_predicate member.fictions, :exists?
      assert ParagraphReportsAccess.allowed?(member)
    end

    test 'guests are denied' do
      assert_not ParagraphReportsAccess.allowed?(nil)
    end
  end
end
