# frozen_string_literal: true

module SessionDiagnostics
  # Structured production logs for unexpected session loss and auth failures.
  class Logger
    SESSION_COOKIE = '_tanooki_session'

    class << self
      def log_auth_failure(request, opts = {})
        log(request, event: 'auth_failure', failure_action: opts[:action], failure_scope: opts[:scope])
      end

      def log_client_report(request, payload = {})
        log(
          request,
          event: 'client_report',
          reason: payload[:reason],
          page_url: payload[:page_url]
        )
      end

      private

      def log(request, **attrs)
        Rails.logger.warn("[SessionDiagnostics] #{summary_for(request, attrs).to_json}")
      end

      def summary_for(request, attrs)
        request_context(request).merge(event_context(attrs)).compact
      end

      def request_context(request)
        {
          path: request.fullpath,
          method: request.request_method,
          session_cookie: request.cookies.key?(SESSION_COOKIE),
          remember_cookie: remember_cookie_present?(request),
          cf_ray: request.headers['CF-Ray'],
          user_agent: request.user_agent&.truncate(200),
          referrer: request.referer&.truncate(200)
        }
      end

      def event_context(attrs)
        {
          event: attrs[:event],
          failure_action: attrs[:failure_action],
          failure_scope: attrs[:failure_scope],
          reason: attrs[:reason],
          page_url: attrs[:page_url]&.truncate(200)
        }
      end

      def remember_cookie_present?(request)
        request.cookies.keys.any? { |name| name.include?('remember') }
      end
    end
  end
end
