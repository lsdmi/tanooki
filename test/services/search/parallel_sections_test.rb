# frozen_string_literal: true

require 'test_helper'

module Search
  class ParallelSectionsTest < ActiveSupport::TestCase
    test 'runs section loaders concurrently and returns named results' do
      started = Concurrent::Array.new

      result = Search::ParallelSections.call(
        a: lambda {
          started << :a
          sleep 0.05
          :A
        },
        b: lambda {
          started << :b
          sleep 0.05
          :B
        }
      )

      assert_equal({ a: :A, b: :B }, result)
      assert_equal %i[a b].sort, started.to_a.sort
    end

    test 're-raises the first section error after waiting' do
      error = assert_raises(RuntimeError) do
        Search::ParallelSections.call(
          ok: -> { :ok },
          boom: -> { raise 'section failed' }
        )
      end

      assert_equal 'section failed', error.message
    end
  end
end
