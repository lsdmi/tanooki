# frozen_string_literal: true

require 'test_helper'

class TalesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @tale = publications(:tale_approved_one)
    @controller = TalesController.new
  end

  test 'should get show' do
    Publication.stub :search, [publications(:tale_approved_one), publications(:tale_created_one)] do
      get tale_url(@tale)
      assert_response :success
    end
  end

  test 'should increment views for publication' do
    session = {}
    @controller.stub(:session, session) do
      @controller.instance_variable_set(:@publication, @tale)
      @tale.update(views: 0)
      @controller.send(:track_visit)
      assert_equal 1, @tale.reload.views
    end
  end

  test 'should not increment views for publication if already viewed' do
    session = { viewed_publications: [@tale.id] }
    @controller.stub(:session, session) do
      @controller.instance_variable_set(:@publication, @tale)
      @tale.update(views: 0)
      @controller.send(:track_visit)
      assert_equal 0, @tale.reload.views
    end
  end

  test 'should add publication id to viewed_publications session variable' do
    session = {}
    @controller.stub(:session, session) do
      @controller.instance_variable_set(:@publication, @tale)
      @tale.update(views: 0)
      @controller.send(:track_visit)
      assert_equal [@tale.id], session[:viewed_publications]
    end
  end

  test 'should not add publication id to viewed_publications session variable if already viewed' do
    session = { viewed_publications: [@tale.id] }
    @controller.stub(:session, session) do
      @controller.instance_variable_set(:@publication, @tale)
      @tale.update(views: 0)
      @controller.send(:track_visit)
      assert_equal [@tale.id], session[:viewed_publications]
    end
  end

  test '#more_tails should return 6 publications' do
    @controller.instance_variable_set(:@publication, @tale)
    publications = 10.times.map { |_n| publications(:tale_created_one) }
    Publication.stub :search, publications do
      assert_equal 6, @controller.send(:more_tails).size
    end
  end

  test '#more_tails should exclude the current publication' do
    @controller.instance_variable_set(:@publication, @tale)
    publications = 10.times.map { |_n| publications(:tale_created_one) }
    publications << @tale
    Publication.stub :search, publications do
      assert_not_includes @controller.send(:more_tails), @tale
    end
  end
end
