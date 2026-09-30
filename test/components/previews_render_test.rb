# frozen_string_literal: true

require 'test_helper'

class PreviewsRenderTest < ViewComponentTestCase
  ViewComponent::Preview.all.select { |preview| preview.name.start_with?('Ui::') }.each do |preview|
    preview.examples.each do |example|
      test "#{preview.preview_name}/#{example} renders" do
        render_preview(example, from: preview)

        assert_operator rendered_content.strip.length, :>, 0
      end
    end
  end
end
