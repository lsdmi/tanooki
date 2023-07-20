if Rails.env.production?
  Searchkick.client_options = {
    url: "http://167.71.63.106:9200",
    transport_options: {
      headers: { "Authorization" => "Basic #{Base64.strict_encode64("#{ENV['ELASTICSEARCH_USER']}:#{ENV['ELASTICSEARCH_PASSWORD']}")}" }
    }
  }
end
