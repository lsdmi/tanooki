# frozen_string_literal: true

if Rails.env.production?
  credentials = [
    ENV.fetch('ELASTICSEARCH_USER', nil),
    ENV.fetch('ELASTICSEARCH_PASSWORD', nil)
  ].join(':')

  Searchkick.client_options = {
    url: ENV.fetch('ELASTICSEARCH_URL'),
    transport_options: {
      headers: { 'Authorization' => "Basic #{Base64.strict_encode64(credentials)}" }
    }
  }
end
