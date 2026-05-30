# frozen_string_literal: true

module Content
  # Adult-content acknowledgement state and disclaimer visibility for fiction pages.
  module AdultContentHelper
    def adult_content_acknowledged?
      return true if current_user&.adult_content_acknowledged?

      session[:adult_content_ack].present?
    end

    def show_adult_content_disclaimer?(fiction)
      fiction.adult_content? && !adult_content_acknowledged?
    end
  end
end
