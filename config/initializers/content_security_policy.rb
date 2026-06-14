# frozen_string_literal: true

# Report-only CSP for production. Tune directives after reviewing browser console violations.
# https://guides.rubyonrails.org/security.html#content-security-policy-header

if Rails.env.production?
  Rails.application.configure do
    config.content_security_policy do |policy|
      policy.default_src :self, :https
      policy.base_uri    :self
      policy.font_src    :self, :https, :data, 'https://fonts.gstatic.com'
      policy.img_src     :self, :https, :data, :blob
      policy.object_src  :none
      policy.script_src  :self, :https, :unsafe_inline,
                         'https://cdn.jsdelivr.net',
                         'https://cdnjs.cloudflare.com',
                         'https://ga.jspm.io',
                         'https://pagead2.googlesyndication.com'
      policy.style_src   :self, :https, :unsafe_inline,
                         'https://fonts.googleapis.com',
                         'https://cdn.jsdelivr.net'
      policy.connect_src :self, :https, 'wss://baka.in.ua'
      policy.frame_src   :self, :https, 'https://googleads.g.doubleclick.net', 'https://tpc.googlesyndication.com'
      policy.worker_src  :self, :blob
      policy.report_uri  '/csp-violation-report'
    end

    config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
    config.content_security_policy_nonce_directives = %w[script-src]

    config.content_security_policy_report_only = true
  end
end
