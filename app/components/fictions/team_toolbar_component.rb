# frozen_string_literal: true

module Fictions
  # Management links on fiction#show for the fiction's teams and admins, above the About and Chapters panels.
  # Hidden on Comments through the tabs root's `group/tabs`, since the tab switches on the client.
  class TeamToolbarComponent < ViewComponent::Base
    include Layout::TurboDriveHelper
    include Ui::StrokeIconHelper

    def initialize(fiction:, user:)
      super()
      @fiction = fiction
      @user = user
    end

    def render?
      user.present? && user.manages_fiction?(fiction)
    end

    private

    attr_reader :fiction, :user
  end
end
