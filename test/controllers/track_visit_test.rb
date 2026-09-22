# frozen_string_literal: true

require 'test_helper'

class TrackVisitTest < ActiveSupport::TestCase
  class HostController < ApplicationController
    public :track_visit
  end

  setup do
    @controller = HostController.new
    @fiction = fictions(:one)
    @session = {}
  end

  test 'track_visit with nil record does not call ViewIncrement' do
    called = false
    builder = lambda { |*|
      called = true
      raise 'should not build'
    }

    Analytics::ViewIncrement.stub(:new, builder) do
      @controller.stub(:session, @session) do
        @controller.stub(:turbo_prefetch_request?, false) do
          @controller.track_visit(nil)
        end
      end
    end

    assert_not called
  end

  test 'track_visit passes the given record to ViewIncrement' do
    seen = nil
    fake = Object.new
    fake.define_singleton_method(:call) { nil }

    Analytics::ViewIncrement.stub(:new, lambda { |record, session|
      seen = [record, session]
      fake
    }) do
      @controller.stub(:session, @session) do
        @controller.stub(:turbo_prefetch_request?, false) do
          @controller.track_visit(@fiction)
        end
      end
    end

    assert_equal [@fiction, @session], seen
  end

  test 'track_visit skips turbo prefetch requests' do
    called = false
    builder = lambda { |*|
      called = true
      raise 'should not build'
    }

    Analytics::ViewIncrement.stub(:new, builder) do
      @controller.stub(:session, @session) do
        @controller.stub(:turbo_prefetch_request?, true) do
          @controller.track_visit(@fiction)
        end
      end
    end

    assert_not called
  end
end
