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

    test 'tinymce is required on chapter and publication forms only' do
      assign_controller(:chapters, :new)

      assert_predicate self, :requires_tinymce?

      assign_controller(:chapters, :show)

      assert_not_predicate self, :requires_tinymce?

      assign_controller(:publications, :edit)

      assert_predicate self, :requires_tinymce?
    end

    test 'font toggler loads on tale show only' do
      assign_controller(:tales, :show)

      assert_predicate self, :requires_legacy_font_toggler?

      assign_controller(:tales, :index)

      assert_not_predicate self, :requires_legacy_font_toggler?
    end

    test 'mode toggler skips immersive chapter reader only' do
      assign_controller(:chapters, :show)

      assert_not_predicate self, :requires_mode_toggler?

      assign_controller(:fictions, :show)

      assert_predicate self, :requires_mode_toggler?
    end

    test 'reader google fonts load on chapter reader only' do
      assign_controller(:chapters, :show)

      assert_predicate self, :requires_reader_google_fonts?

      assign_controller(:fictions, :show)

      assert_not_predicate self, :requires_reader_google_fonts?
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
