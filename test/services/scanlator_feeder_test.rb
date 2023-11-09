# frozen_string_literal: true

require 'test_helper'

class ScanlatorFeederTest < ActiveSupport::TestCase
  def setup
    @fiction = fictions(:one)
    @scanlator = scanlators(:one)
    @service = ScanlatorFeeder.new(fiction_size: 1, scanlator: @scanlator)
  end

  test 'call method should fetch the feed' do
    result = @service.call
    assert_not_nil result
    assert_equal [Fiction.first, Chapter.first], result
  end
end
