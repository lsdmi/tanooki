# frozen_string_literal: true

class TrackingService
  def initialize(object, session)
    @object = object
    @session = session
  end

  def call
    return if @session[:viewed]&.include?(@object.slug)

    @object.increment!(:views)
    @session[:viewed] ||= []
    @session[:viewed] << @object.slug
  end
end
