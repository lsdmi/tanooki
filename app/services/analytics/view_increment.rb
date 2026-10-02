# frozen_string_literal: true

module Analytics
  # Records a view once per content identifier in the current session (rolling last 10).
  # Session dedup runs synchronously; ViewCounter writes the count later, off the request path.
  class ViewIncrement
    def initialize(object, session)
      @object = object
      @session = session
    end

    def call
      return unless @object
      return if already_viewed?

      remember_view
      ViewCounter.default.add(@object)
    end

    private

    def already_viewed?
      @session[:viewed]&.include?(view_identifier)
    end

    def view_identifier
      @object.respond_to?(:slug) ? @object.slug : @object.sqid
    end

    def remember_view
      @session[:viewed] = Array(@session[:viewed]) << view_identifier
      @session[:viewed] = @session[:viewed].last(10)
    end
  end
end
