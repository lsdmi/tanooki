# frozen_string_literal: true

if Rails.env.production? || (Rails.env.development? && ENV['OPENSEARCH_URL'].present?)
  require 'opensearch-ruby'

  credentials = [
    ENV.fetch('OPENSEARCH_USER'),
    ENV.fetch('OPENSEARCH_PASSWORD')
  ].join(':')

  transport_options = {
    request: {
      open_timeout: ENV.fetch('OPENSEARCH_OPEN_TIMEOUT', 2).to_i,
      timeout: ENV.fetch('OPENSEARCH_TIMEOUT', 60).to_i
    },
    headers: { 'Authorization' => "Basic #{Base64.strict_encode64(credentials)}" }
  }

  ca_cert = ENV['OPENSEARCH_CA_CERT'].presence
  if ca_cert
    ca_file = Rails.root.join('tmp/opensearch-ca.crt')
    File.write(ca_file, ca_cert.gsub('\\n', "\n"))
    transport_options[:ssl] = { ca_file: ca_file.to_s }
  end

  opensearch_url = ENV.fetch('OPENSEARCH_URL')

  Searchkick.client = OpenSearch::Client.new(
    url: opensearch_url,
    transport_options: transport_options
  )

  Searchkick.client_options = {
    url: opensearch_url,
    transport_options: transport_options
  }
end
