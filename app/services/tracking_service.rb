# frozen_string_literal: true

class TrackingService
  def initialize(object, session)
    @object = object
    @session = session
  end

  def call
    return unless @object

    identifier = @object.respond_to?(:slug) ? @object.slug : @object.sqid
    return if @session[:viewed]&.include?(identifier)

    @object.increment!(:views)
    @session[:viewed] ||= []
    @session[:viewed] << identifier
    @session[:viewed] = @session[:viewed].last(10)
  end
end
