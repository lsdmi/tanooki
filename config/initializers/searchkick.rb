# frozen_string_literal: true

if Rails.env.production?
  require 'opensearch-ruby'

  credentials = [
    ENV.fetch('OPENSEARCH_USER'),
    ENV.fetch('OPENSEARCH_PASSWORD')
  ].join(':')

  transport_options = {
    request: {
      open_timeout: ENV.fetch('OPENSEARCH_OPEN_TIMEOUT', 2).to_i,
      timeout: ENV.fetch('OPENSEARCH_TIMEOUT', 5).to_i
    },
    headers: { 'Authorization' => "Basic #{Base64.strict_encode64(credentials)}" }
  }

  ca_file = Rails.root.join('tmp/opensearch-ca.crt')
  File.write(ca_file, ENV.fetch('OPENSEARCH_CA_CERT').gsub('\\n', "\n"))
  transport_options[:ssl] = { ca_file: ca_file.to_s }

  Searchkick.client = OpenSearch::Client.new(
    url: ENV.fetch('OPENSEARCH_URL'),
    transport_options: transport_options
  )

  Searchkick.client_options = {
    url: ENV.fetch('OPENSEARCH_URL'),
    transport_options: transport_options
  }
end
