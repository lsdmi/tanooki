# frozen_string_literal: true

# Loaded by studio_tab_loadable*_test.rb after test_helper.

# Minimal object including the concern so we can exercise private methods without a full controller.
class StudioTabLoadableHarness
  include StudioTabLoadable

  attr_accessor :params, :session, :current_user

  def initialize(user)
    @current_user = user
    @params = ActionController::Parameters.new({})
    @session = {}
  end
end

module StudioTabLoadableStubHelpers
  private

  def stub_tab_content_service(overrides = {})
    defaults = {
      pagy: nil, pokemon_show: nil, fictions: nil, publications: nil,
      scanlators: nil, comments: nil, avatars: nil, bookshelves: nil
    }
    Object.new.tap do |service|
      defaults.merge(overrides).each { |key, val| service.instance_variable_set(:"@#{key}", val) }
    end
  end
end
