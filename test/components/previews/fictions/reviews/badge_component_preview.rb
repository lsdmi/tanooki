# frozen_string_literal: true

module Fictions
  module Reviews
    # Needs no database: the badge only shows the author’s rating and the chapters read, passed in as numbers.
    class BadgeComponentPreview < ViewComponent::Preview
      # @label Відгук: 4 зірки, прочитано 12 розділів
      def read_many
        render BadgeComponent.new(rating: 4, read_count: 12)
      end

      # @label Відгук: 5 зірок, прочитано 1 розділ
      def read_one
        render BadgeComponent.new(rating: 5, read_count: 1)
      end

      # @label Відгук: 3 зірки, жодного розділу
      def read_none
        render BadgeComponent.new(rating: 3, read_count: 0)
      end
    end
  end
end
