# frozen_string_literal: true

namespace :assets do
  desc 'Precompile and upload digested assets to Spaces (production DO build)'
  task deploy: :environment do
    Rake::Task['assets:precompile'].invoke
    Rake::Task['assets:sync_to_cdn'].reenable
    Rake::Task['assets:sync_to_cdn'].invoke
  end

  desc 'Upload public/assets to Spaces (needs STORAGE_ACCESS_KEY; CDN host from PlatformConfig)'
  task sync_to_cdn: :environment do
    abort 'assets:sync_to_cdn is for RAILS_ENV=production only' unless Rails.env.production?

    if ENV['STORAGE_ACCESS_KEY'].present?
      assets_dir = Rails.public_path.join('assets')
      abort 'Missing public/assets — run assets:precompile first' unless assets_dir.directory?

      prefix = ENV.fetch('ASSET_CDN_PREFIX', 'assets')
      uploaded = AssetsCdnUploader.new(prefix: prefix).upload!(assets_dir)
      bucket = PlatformConfig::Storage::BUCKET
      cdn = PlatformConfig::ASSET_CDN_HOST

      puts "Uploaded #{uploaded} files to #{bucket}/#{prefix}/ — #{cdn}"
      puts <<~NOTE

        Assets served from #{cdn} via production.rb asset_host proc.
        Before go-live: Spaces CORS for https://#{PlatformConfig::APP_HOST}; assets/* must return 200.
      NOTE
    else
      puts 'Skipping CDN upload (STORAGE_ACCESS_KEY not set)'
    end
  end
end

# Uploads precompiled pipeline files to the same Spaces bucket as Active Storage (separate prefix).
class AssetsCdnUploader
  def initialize(prefix:)
    @prefix = prefix
  end

  def upload!(assets_dir)
    require 'aws-sdk-s3'
    count = 0

    assets_dir.find do |path|
      next unless path.file?

      put_file(path, path.relative_path_from(assets_dir))
      count += 1
    end

    count
  end

  private

  def put_file(path, relative)
    key = File.join(@prefix, relative.to_s)
    content_type = Marcel::MimeType.for(path, name: path.basename.to_s) || 'application/octet-stream'

    s3_client.put_object(
      bucket: PlatformConfig::Storage::BUCKET,
      key: key,
      body: path.read,
      acl: 'public-read',
      content_type: content_type,
      cache_control: "public, max-age=#{1.year.to_i}"
    )
  end

  def s3_client
    @s3_client ||= Aws::S3::Client.new(
      access_key_id: ENV.fetch('STORAGE_ACCESS_KEY'),
      secret_access_key: ENV.fetch('STORAGE_SECRET_KEY'),
      region: PlatformConfig::Storage::REGION,
      endpoint: PlatformConfig::Storage::ENDPOINT
    )
  end
end
