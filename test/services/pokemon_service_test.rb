# frozen_string_literal: true

require 'test_helper'

class PokemonServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:user_one)
    @session = {}
    @service = PokemonService.new(session: @session, user: @user)
  end

  test 'call method should return caught Pokemon when catch succeeds' do
    Time.stub :now, 1.day.ago do
      result = @service.call
      assert_not_nil result, 'Caught Pokemon should not be nil'
    end
  end
end
