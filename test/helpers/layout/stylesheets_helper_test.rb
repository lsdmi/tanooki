# frozen_string_literal: true

require 'test_helper'

module Layout
  class StylesheetsHelperTest < ActionView::TestCase
    include Devise::Test::IntegrationHelpers
    include Chapters::ReaderBottomHelper
    include Layout::PageContextHelper
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

    test 'chapter show loads reader and actiontext styles' do
      chapter = chapters(:one)
      chapter.fiction.update!(adult_content: true)
      assign_controller(:chapters, :show, chapter: chapter, fiction: chapter.fiction)

      assert_includes page_stylesheets, 'chapters_reader'
      assert_includes page_stylesheets, 'actiontext'
      assert_not_includes page_stylesheets, 'pagy'
    end

    test 'chapter show loads adult disclaimer styles for gated fiction' do
      chapter = chapters(:one)
      chapter.fiction.update!(adult_content: true)
      assign_controller(:chapters, :show, chapter: chapter, fiction: chapter.fiction)

      assert_includes page_stylesheets, 'adult_content_disclaimer'
    end

    test 'fiction show loads adult disclaimer styles only when gate is active' do
      fiction = fictions(:one)
      fiction.update!(adult_content: true)
      assign_controller(:fictions, :show, fiction: fiction)

      assert_includes page_stylesheets, 'adult_content_disclaimer'
      assert_not_includes page_stylesheets, 'chapters_reader'
    end

    test 'fiction show loads reader styles when translator support card is shown' do
      fiction = fictions(:one)
      fiction.scanlators.first.update!(bank_url: 'https://send.monobank.ua/jar/example')
      assign_controller(:fictions, :show, fiction: fiction)

      assert_includes page_stylesheets, 'chapters_reader'
    end

    test 'library index loads pagy styles only' do
      assign_controller(:library, :index)

      assert_equal ['pagy'], page_stylesheets
    end

    test 'chapter form loads slimselect and flatpickr overrides' do
      assign_controller(:chapters, :new)

      assert_equal %w[slimselect flatpickr_overrides], page_stylesheets
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
