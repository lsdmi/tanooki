# frozen_string_literal: true

# Async callbacks need a Solid Queue worker (`bin/jobs start` / `bin/dev`). In local dev with
# OpenSearch configured, index inline so new records appear in search without a worker.
module SearchkickCallbacks
  def self.mode
    return false unless Rails.env.production? || ENV['OPENSEARCH_URL'].present?

    Rails.env.development? ? :inline : :async
  end
end

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
    store = OpenSSL::X509::Store.new
    ca_cert.gsub('\\n', "\n").scan(/-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----/m).each do |cert_pem|
      store.add_cert(OpenSSL::X509::Certificate.new(cert_pem))
    end
    transport_options[:ssl] = { cert_store: store }
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
