# frozen_string_literal: true

require 'test_helper'

module FictionTags
  class RefreshFictionsTest < ActiveSupport::TestCase
    test 'touches only the given works' do
      one = fictions(:one)
      two = fictions(:two)
      stamp = 1.day.ago
      [one, two].each { |fiction| fiction.update!(updated_at: stamp) }

      RefreshFictions.call([one.id, one.id])

      assert_operator one.reload.updated_at, :>, stamp + 1.hour
      assert_in_delta stamp, two.reload.updated_at, 1
    end
  end
end
