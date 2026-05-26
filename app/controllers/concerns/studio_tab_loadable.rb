# frozen_string_literal: true

# Shared Studio UI behavior: resolves the active tab from params/session, loads tab payload
# via {Studio::TabContent}, and assigns controller instance variables for the tab partial.
module StudioTabLoadable
  extend ActiveSupport::Concern

  private

  def set_active_tab
    requested = params[:tab].presence || session[:studio_tab].presence || default_tab
    @active_tab = Studio::TabCatalog.normalize_tab_id(requested)
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
    service.to_controller_assignments.each do |name, value|
      instance_variable_set(:"@#{name}", value)
    end

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
    @epub_export_requests ||= []
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName
end
