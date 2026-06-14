# frozen_string_literal: true

module StructuredData
  # Renders JSON-LD inside a script tag without HTML-escaping the JSON payload.
  module JsonLdScriptHelper
    def json_ld_script(json_payload)
      content = json_payload.to_s.gsub('</', '<\\/')
      tag.script(content, type: 'application/ld+json', escape: false, nonce: content_security_policy_nonce)
    end
  end
end
