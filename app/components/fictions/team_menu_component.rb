# frozen_string_literal: true

module Fictions
  # «Керування» menu in the hero actions for the fiction's teams and admins: add a chapter, manage chapters, edit.
  # Lives in the hero so it stays reachable on every tab.
  class TeamMenuComponent < ViewComponent::Base
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
