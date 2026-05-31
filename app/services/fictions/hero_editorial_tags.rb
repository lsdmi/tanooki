# frozen_string_literal: true

module Fictions
  # Picks which editorial badge kinds to show on a fiction hero slide (max 2).
  class HeroEditorialTags
    EDITORIAL_PRIORITY = %i[novelty popular update].freeze

    def initialize(fiction, popular_novelty_ids:, top_fiction_ids:, latest_update_ids:)
      @fiction = fiction
      @popular_novelty_ids = popular_novelty_ids
      @top_fiction_ids = top_fiction_ids
      @latest_update_ids = latest_update_ids
    end

    def call
      kinds = []
      kinds << :adult if @fiction.adult_content?

      EDITORIAL_PRIORITY.each do |kind|
        kinds << kind if badge?(kind)
      end

      kinds.first(Ui::EditorialTagComponent::HERO_MAX)
    end

    private

    def badge?(kind)
      case kind
      when :novelty then @popular_novelty_ids.include?(@fiction.id)
      when :popular then @top_fiction_ids.include?(@fiction.id)
      when :update then @latest_update_ids.include?(@fiction.id)
      else false
      end
    end
  end
end
