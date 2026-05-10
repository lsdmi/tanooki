# frozen_string_literal: true

# Shared Studio UI behavior: resolves the active tab from params/session, loads tab payload
# via {Studio::TabContent}, and assigns controller instance variables for the tab partial.
module StudioTabLoadable
  extend ActiveSupport::Concern

  private

  def set_active_tab
    requested = params[:tab].presence || session[:studio_tab].presence || default_tab
    @active_tab = Studio.normalize_tab_id(requested)
    session[:studio_tab] = @active_tab
  end

  def default_tab
    'blogs'
  end

  def load_tab_content
    service = Studio::TabContent.new(current_user, @active_tab, params)
    service.call
    assign_instance_variables_from_service(service)
  end

  def assign_instance_variables_from_service(service)
    @pagy = service.instance_variable_get(:@pagy)
    @publications = service.instance_variable_get(:@publications)
    @pokemon_show = service.instance_variable_get(:@pokemon_show)
    @scanlators = service.instance_variable_get(:@scanlators)
    @fictions = service.instance_variable_get(:@fictions)
    @comments = service.instance_variable_get(:@comments)
    @avatars = service.instance_variable_get(:@avatars)
    @bookshelves = service.instance_variable_get(:@bookshelves)

    assign_instance_variables
  end

  # rubocop:disable Naming/MemoizedInstanceVariableName -- ||= defaults tab collection ivars; not memoizing this method
  def assign_instance_variables
    @comments ||= []
    @fictions ||= []
    @publications ||= []
    @avatars ||= []
    @scanlators ||= []
    @bookshelves ||= []
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName
end
