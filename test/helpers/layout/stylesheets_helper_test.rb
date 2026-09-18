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

    test 'global stylesheet list is empty' do
      assert_empty global_stylesheets
    end

    test 'chapter show loads reader actiontext and adult disclaimer sheets' do
      chapter = chapters(:one)
      chapter.fiction.update!(adult_content: true)
      assign_controller(:chapters, :show, chapter: chapter, fiction: chapter.fiction)

      assert_equal %w[actiontext chapters_reader adult_content_disclaimer], page_stylesheets
    end

    test 'fiction show loads adult disclaimer only when gate is active' do
      fiction = fictions(:one)
      fiction.update!(adult_content: true)
      assign_controller(:fictions, :show, fiction: fiction)

      assert_equal %w[adult_content_disclaimer], page_stylesheets
    end

    test 'studio index loads sweetalert styles' do
      assign_controller(:studio, :index)

      assert_equal %w[sweetal2], page_stylesheets
    end

    test 'fiction show with reader support card does not load chapters_reader' do
      fiction = fictions(:one)
      fiction.scanlators.first.update!(bank_url: 'https://send.monobank.ua/jar/example')
      assign_controller(:fictions, :show, fiction: fiction)

      assert_not_includes page_stylesheets, 'chapters_reader'
    end

    test 'library index has no optional feature stylesheets' do
      assign_controller(:library, :index)

      assert_empty page_stylesheets
    end

    test 'chapter form loads slimselect and flatpickr overrides' do
      assign_controller(:chapters, :new)

      assert_equal %w[slimselect flatpickr_overrides], page_stylesheets
    end

    test 'pagy stylesheet loads when a pagy assign is present' do
      assign_controller(:fictions, :index, pagy: Pagy.new(count: 20, page: 1, limit: 10))

      assert_equal %w[pagy], page_stylesheets
    end

    test 'adsense slot stylesheet loads when adblock check is on' do
      define_singleton_method(:adsense_adblock_check?) { true }
      assign_controller(:home, :index)

      assert_equal %w[adsense_slots], page_stylesheets
    end

    private

    def assign_controller(name, action, chapter: nil, fiction: nil, **extra_assigns)
      @controller.instance_variable_set(:@_action_name, action)
      @controller.instance_variable_set(:@_request, @request)
      @controller.define_singleton_method(:controller_name) { name.to_s }
      @controller.define_singleton_method(:controller_path) { name.to_s }
      @controller.define_singleton_method(:action_name) { action.to_s }
      view_assigns = extra_assigns.stringify_keys
      view_assigns['chapter'] = chapter if chapter
      view_assigns['fiction'] = fiction if fiction
      @controller.define_singleton_method(:view_assigns) { view_assigns }
    end
  end
end
