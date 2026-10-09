# frozen_string_literal: true

module Oauth
  # Dynamic client registration. Public clients only, and only the known redirect hosts.
  class RegistrationsController < ActionController::API
    rate_limit to: 10, within: 1.minute, by: -> { client_ip },
               with: -> { render json: { error: 'rate_limited' }, status: :too_many_requests }

    def create
      render json: RegisterClient.call(registration_params), status: :created
    rescue RegisterClient::Rejected => e
      render json: { error: e.code }, status: :bad_request
    end

    private

    def registration_params
      params.permit(:client_name, :token_endpoint_auth_method, redirect_uris: [], grant_types: [], response_types: [])
    end

    def client_ip
      request.headers['CF-Connecting-IP'].presence || request.remote_ip
    end
  end
end
