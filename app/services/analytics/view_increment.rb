# frozen_string_literal: true

module Analytics
  # Increments AR +views+ once per content identifier in the current session (rolling last 10).
  class ViewIncrement
    def initialize(object, session)
      @object = object
      @session = session
    end

    def call
      return unless @object
      return if already_viewed?

      record_view
      remember_view
    end

    private

    def already_viewed?
      @session[:viewed]&.include?(view_identifier)
    end

    def view_identifier
      @object.respond_to?(:slug) ? @object.slug : @object.sqid
    end

    def record_view
      @object.with_lock do
        @object.class.increment_counter(:views, @object.id)
        @object.views += 1
      end
    end

    def remember_view
      @session[:viewed] = Array(@session[:viewed]) << view_identifier
      @session[:viewed] = @session[:viewed].last(10)
    end
  end
end
