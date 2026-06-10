# frozen_string_literal: true

require 'test_helper'

module Layout
  class AssetRequirementsHelperTest < ActionView::TestCase
    include AssetRequirementsHelper
    include Layout::AdultContentHelper

    setup do
      @controller = ApplicationController.new
      @request = ActionDispatch::TestRequest.create
      @controller.request = @request
    end

    test 'studio loads sweetalert JS and CSS' do
      assign_controller(:studio, :index)

      assert_predicate self, :requires_sweetalert?
      assert_predicate self, :requires_sweetalert_styles?
    end

    test 'fiction show loads sweetalert CSS only' do
      assign_controller(:fictions, :show)

      assert_not_predicate self, :requires_sweetalert?
      assert_predicate self, :requires_sweetalert_styles?
    end

    test 'tinymce is required on chapter and publication forms only' do
      assign_controller(:chapters, :new)

      assert_predicate self, :requires_tinymce?

      assign_controller(:chapters, :show)

      assert_not_predicate self, :requires_tinymce?

      assign_controller(:publications, :edit)

      assert_predicate self, :requires_tinymce?
    end

    test 'accordion JS loads on fiction and chapter show only' do
      assign_controller(:fictions, :show)

      assert_predicate self, :requires_accordion_js?

      assign_controller(:fictions, :index)

      assert_not_predicate self, :requires_accordion_js?
    end

    test 'font toggler loads on tale show only' do
      assign_controller(:tales, :show)

      assert_predicate self, :requires_legacy_font_toggler?

      assign_controller(:tales, :index)

      assert_not_predicate self, :requires_legacy_font_toggler?
    end

    test 'pagy styles follow controller path list' do
      assign_controller(:library, :index, path: 'library')

      assert_predicate self, :requires_pagy_styles?

      assign_controller(:home, :index, path: 'home')

      assert_not_predicate self, :requires_pagy_styles?
    end

    private

    def assign_controller(name, action, path: nil)
      path ||= name.to_s
      @controller.define_singleton_method(:controller_name) { name.to_s }
      @controller.define_singleton_method(:controller_path) { path }
      @controller.define_singleton_method(:action_name) { action.to_s }
      @controller.define_singleton_method(:view_assigns) { {} }
    end
  end
end
