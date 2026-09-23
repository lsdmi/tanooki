# frozen_string_literal: true

module Ui
  # 16+ info banner or 18+ hard gate on fiction show and the chapter reader.
  class AgeRatingNotice < ViewComponent::Base
    include AgeRatingNoticeStyles

    RATINGS = %i[sixteen eighteen].freeze

    def initialize(rating:, reader_gate: false)
      super()
      @rating = rating.to_sym
      @reader_gate = reader_gate
      raise ArgumentError, "unknown rating: #{@rating}" unless RATINGS.include?(@rating)
    end

    private

    attr_reader :rating, :reader_gate

    def eighteen?
      rating == :eighteen
    end

    def title_key
      reader_gate ? 'reader_title' : 'title'
    end

    def t_notice(key)
      I18n.t("fictions.age_rating_notice.#{rating}.#{key}")
    end

    def root_classes
      eighteen? ? EIGHTEEN_ROOT : SIXTEEN_ROOT
    end

    def icon_wrap_classes
      eighteen? ? EIGHTEEN_ICON_WRAP : SIXTEEN_ICON_WRAP
    end

    def icon_classes
      eighteen? ? EIGHTEEN_ICON : SIXTEEN_ICON
    end

    def description_classes
      eighteen? ? EIGHTEEN_DESCRIPTION : SIXTEEN_DESCRIPTION
    end

    def dismiss_classes
      eighteen? ? EIGHTEEN_DISMISS : SIXTEEN_DISMISS
    end
  end
end
