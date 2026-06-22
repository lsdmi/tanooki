# frozen_string_literal: true

require 'test_helper'

module Layout
  class StylesheetsHelperTest < ActionView::TestCase
    include Devise::Test::IntegrationHelpers
    include Layout::StylesheetsHelper
    include Layout::AdultContentHelper

    setup do
      @controller = ApplicationController.new
      @request = ActionDispatch::TestRequest.create
      @controller.request = @request
      @session = {}
    end

    def current_user
      nil
    end

    attr_reader :session

    test 'chapter show loads only page-specific stylesheets' do
      chapter = chapters(:one)
      chapter.fiction.update!(adult_content: true)
      assign_controller(:chapters, :show, chapter: chapter, fiction: chapter.fiction)

      assert_equal %w[adult_content_disclaimer], page_stylesheets
    end

    test 'chapter show loads adult disclaimer styles for gated fiction' do
      chapter = chapters(:one)
      chapter.fiction.update!(adult_content: true)
      assign_controller(:chapters, :show, chapter: chapter, fiction: chapter.fiction)

      assert_includes page_stylesheets, 'adult_content_disclaimer'
    end

    test 'fiction show loads adult disclaimer only when gate is active' do
      fiction = fictions(:one)
      fiction.update!(adult_content: true)
      assign_controller(:fictions, :show, fiction: fiction)

      assert_equal %w[adult_content_disclaimer], page_stylesheets
    end

    test 'global_stylesheets includes sweetalert for studio show morph parity' do
      assert_includes global_stylesheets, 'sweetal2'
    end

    test 'global_stylesheets includes reader and shared bundles' do
      assert_equal %w[pagy slimselect actiontext chapters_reader sweetal2], global_stylesheets
    end

    test 'fiction show with reader support card does not load chapters_reader separately' do
      fiction = fictions(:one)
      fiction.scanlators.first.update!(bank_url: 'https://send.monobank.ua/jar/example')
      assign_controller(:fictions, :show, fiction: fiction)

      assert_not_includes page_stylesheets, 'chapters_reader'
    end

    test 'library index has no global-duplicated optional stylesheets' do
      assign_controller(:library, :index)

      assert_empty page_stylesheets
    end

    test 'chapter form loads flatpickr overrides only' do
      assign_controller(:chapters, :new)

      assert_equal %w[flatpickr_overrides], page_stylesheets
    end

    private

    def assign_controller(name, action, chapter: nil, fiction: nil)
      @controller.instance_variable_set(:@_action_name, action)
      @controller.instance_variable_set(:@_request, @request)
      @controller.define_singleton_method(:controller_name) { name.to_s }
      @controller.define_singleton_method(:controller_path) { name.to_s }
      @controller.define_singleton_method(:action_name) { action.to_s }
      view_assigns = {}
      view_assigns['chapter'] = chapter if chapter
      view_assigns['fiction'] = fiction if fiction
      @controller.define_singleton_method(:view_assigns) { view_assigns }
    end
  end
end
