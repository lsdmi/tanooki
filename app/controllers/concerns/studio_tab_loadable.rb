# frozen_string_literal: true

# Shared Studio UI behavior: resolves the active tab from params/session, loads tab payload
# via {Studio::TabContent}, and assigns controller instance variables for the tab partial.
module StudioTabLoadable
  extend ActiveSupport::Concern

  STUDIO_TAB_COLLECTION_DEFAULTS = %i[
    comments fictions publications avatars scanlators bookshelves epub_export_requests
    cover_quality_flags
  ].freeze

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

  def assign_instance_variables
    STUDIO_TAB_COLLECTION_DEFAULTS.each do |name|
      ivar = :"@#{name}"
      default = name == :cover_quality_flags ? {} : []
      instance_variable_set(ivar, instance_variable_get(ivar) || default)
    end
  end
end
