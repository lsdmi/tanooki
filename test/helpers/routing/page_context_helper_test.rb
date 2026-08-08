# frozen_string_literal: true

require 'test_helper'

module Routing
  class PageContextHelperTest < ActionView::TestCase
    include PageContextHelper

    setup do
      @controller = ApplicationController.new
      @request = ActionDispatch::TestRequest.create
      @controller.request = @request
    end

    test 'chapters_show_page? is true on chapter show' do
      assign_controller(:chapters, :show)

      assert_predicate self, :chapters_show_page?
      assert_not_predicate self, :tales_show_page?
    end

    test 'genre_show_page? uses controller_path' do
      assign_controller('fictions/genres', :show, path: 'fictions/genres')

      assert_predicate self, :genre_show_page?
      assert_not_predicate self, :fictions_show_page?
    end

    private

    def assign_controller(name, action, path: nil)
      path ||= name.to_s
      @controller.define_singleton_method(:controller_name) { name.to_s.split('/').last }
      @controller.define_singleton_method(:controller_path) { path }
      @controller.define_singleton_method(:action_name) { action.to_s }
    end
  end
end
