# frozen_string_literal: true

module Api
  module V1
    # Bearer-token API. The public Hikka list stays on ApplicationController and does not inherit this.
    class BaseController < ActionController::API
      READS_PER_MINUTE = 300
      WRITES_PER_MINUTE = 30

      before_action :authenticate_api_token!
      before_action :reject_disabled_writes, unless: :read_request?
      after_action :log_write, unless: :read_request?

      rescue_from Api::Error, with: :render_raised_api_error

      def self.require_scope(scope)
        before_action { enforce_scope(scope) }
      end

      rate_limit to: READS_PER_MINUTE, within: 1.minute, scope: 'api/v1', name: 'read',
                 by: -> { Current.api_token.id }, if: :read_request?,
                 with: -> { render_api_error(:too_many_requests, 'rate_limited') }
      rate_limit to: WRITES_PER_MINUTE, within: 1.minute, scope: 'api/v1', name: 'write',
                 by: -> { Current.api_token.id }, unless: :read_request?,
                 with: -> { render_api_error(:too_many_requests, 'rate_limited') }

      private

      def authenticate_api_token!
        secret = bearer_secret
        return if accept_api_token?(secret) || accept_oauth_token?(secret)

        render_api_error(:unauthorized, 'unauthorized')
      end

      def accept_api_token?(secret)
        token = ApiToken.authenticate(secret)
        return false if token.nil?

        Current.api_token = token
        Current.user = token.user
        touch_last_used(token)
        true
      end

      def accept_oauth_token?(secret)
        access = Api::OauthAccess.from_secret(secret)
        return false if access.nil?

        Current.api_token = access
        Current.user = access.user
        true
      end

      def enforce_scope(scope)
        render_api_error(:forbidden, 'forbidden') unless Current.api_token&.permits?(scope)
      end

      def bearer_secret
        scheme, secret = request.authorization.to_s.split(' ', 2)
        secret if scheme&.casecmp('Bearer')&.zero?
      end

      # At most one write a minute. A burst of reads must not update the row each time.
      def touch_last_used(token)
        return if token.last_used_at&.after?(1.minute.ago)

        token.update!(last_used_at: Time.current, last_used_ip: request.remote_ip.to_s.first(45))
      end

      def read_request?
        request.get? || request.head?
      end

      # One line per write. The secret and the body stay out of the log.
      def log_write
        Rails.logger.info(
          "[API] user=#{Current.user&.id} token=#{Current.api_token&.id} " \
          "action=#{controller_path}##{action_name} chapter=#{logged_chapter_id} status=#{response.status}"
        )
      end

      def logged_chapter_id
        params[:chapter_id].presence || params[:id].presence || created_chapter_id
      end

      def created_chapter_id
        payload = JSON.parse(Array(response.body).join)
        payload['id'] if payload.is_a?(Hash)
      rescue JSON::ParserError, TypeError
        nil
      end

      def reject_disabled_writes
        render_api_error(:forbidden, 'writes_disabled') unless Api::Limits.writes_enabled?
      end

      def render_raised_api_error(error)
        render_api_error(error.status, error.code, details: error.details)
      end

      def render_api_error(status, code, details: nil)
        render json: {
          error: { code: code.to_s, message: I18n.t("api.errors.#{code}"), details: details || {} }
        }, status:
      end
    end
  end
end
