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

      identifier = @object.respond_to?(:slug) ? @object.slug : @object.sqid
      return if @session[:viewed]&.include?(identifier)

      @object.with_lock { @object.update_column(:views, @object.views + 1) } # rubocop:disable Rails/SkipsModelValidations
      @session[:viewed] ||= []
      @session[:viewed] << identifier
      @session[:viewed] = @session[:viewed].last(10)
    end
  end
end
