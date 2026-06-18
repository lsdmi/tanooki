# frozen_string_literal: true

module Ui
  class StarRatingComponentPreview < ViewComponent::Preview
    # @label Ratings
    def variants
      render_with_template(template: 'ui/star_rating_component_preview/variants')
    end
  end
end
