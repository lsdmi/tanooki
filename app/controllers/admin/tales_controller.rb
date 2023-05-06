# frozen_string_literal: true

module Admin
  class TalesController < ApplicationController
    before_action :authenticate_user!, :verify_user_permissions

    def index
      @pagy, @tales = pagy(Tale.order(created_at: :desc), items: 8)
    end
  end
end
