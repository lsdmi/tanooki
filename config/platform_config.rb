# frozen_string_literal: true

# Non-secret DigitalOcean / production infrastructure defaults.
# Secrets (passwords, API keys, access keys) stay in ENV — see .env.example.
module PlatformConfig
  APP_HOST = 'baka.in.ua'

  ASSET_CDN_HOST = 'https://baka-assets.fra1.cdn.digitaloceanspaces.com'

  module Storage
    BUCKET = 'baka-assets'
    # S3 signing region (Frankfurt); endpoint uses DO datacenter slug fra1.
    REGION = 'eu-central-1'
    ENDPOINT = 'https://fra1.digitaloceanspaces.com'
  end

  module OpenSearch
    USER = 'doadmin'
    OPEN_TIMEOUT = 2
    TIMEOUT = 60
  end
end
