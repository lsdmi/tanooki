# frozen_string_literal: true

module Layout
  # Age-rating notice visibility and 18+ acknowledgement state for fiction pages.
  module AdultContentHelper
    def adult_content_acknowledged?
      return true if current_user&.adult_content_acknowledged?

      session[:adult_content_ack].present?
    end

    def show_age_rating_notice?(fiction)
      return false unless fiction.age_labelled?
      return false if adult_content_acknowledged?

      true
    end

    def age_rating_notice_rating(fiction)
      return :eighteen if fiction.content_rating_eighteen?
      return :sixteen if fiction.content_rating_sixteen?

      nil
    end

    def age_rating_reader_gate?(fiction)
      show_age_rating_notice?(fiction) && fiction.age_gated?
    end
  end
end
