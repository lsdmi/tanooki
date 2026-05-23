# frozen_string_literal: true

namespace :assets do
  desc 'Precompile and upload digested assets to Spaces (production DO build)'
  task deploy: :environment do
    Rake::Task['assets:precompile'].invoke
    Rake::Task['assets:sync_to_cdn'].reenable
    Rake::Task['assets:sync_to_cdn'].invoke
  end

  desc 'Upload public/assets to Spaces (needs STORAGE_*; ASSET_HOST is runtime-only on the web app)'
  task sync_to_cdn: :environment do
    abort 'assets:sync_to_cdn is for RAILS_ENV=production only' unless Rails.env.production?

    if ENV['STORAGE_ACCESS_KEY'].present? && ENV['STORAGE_BUCKET'].present?
      assets_dir = Rails.public_path.join('assets')
      abort 'Missing public/assets — run assets:precompile first' unless assets_dir.directory?

      prefix = ENV.fetch('ASSET_CDN_PREFIX', 'assets')
      uploaded = AssetsCdnUploader.new(prefix: prefix).upload!(assets_dir)
      cdn = ENV['ASSET_HOST'].presence || '(set ASSET_HOST on web app to serve from CDN)'

      puts "Uploaded #{uploaded} files to #{ENV.fetch('STORAGE_BUCKET')}/#{prefix}/ — #{cdn}"
      puts <<~NOTE

        ASSET_HOST is runtime-only (web app env). Use the /assets/ proc in production.rb.
        Before enabling ASSET_HOST: Spaces CORS for https://baka.in.ua; assets/* must return 200.
      NOTE
    else
      puts 'Skipping CDN upload (STORAGE_ACCESS_KEY or STORAGE_BUCKET not set)'
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
      bucket: ENV.fetch('STORAGE_BUCKET'),
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
      region: ENV.fetch('STORAGE_REGION'),
      endpoint: ENV.fetch('STORAGE_ENDPOINT')
    )
  end
end
