# frozen_string_literal: true

module Admin
  # Remaining API limits for every account that has a key or a connected chat.
  class ApiLimitsController < ApplicationController
    before_action :authenticate_user!, :verify_user_permissions

    def index
      @accounts = Api::Limits::Usage.accounts
    end
  end
end
