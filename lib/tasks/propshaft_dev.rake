# frozen_string_literal: true

namespace :assets do
  desc 'Refresh tmp/propshaft-dev-manifest.json (new Stimulus controllers, dev digests)'
  task refresh_dev_manifest: :environment do
    abort 'assets:refresh_dev_manifest is for development only' unless Rails.env.development?

    manifest_path = Rails.application.config.assets.manifest_path
    load_path = Rails.application.assets.load_path
    manifest_path.dirname.mkpath
    File.write(manifest_path, load_path.manifest.to_json)

    puts "Updated #{manifest_path}"
    puts 'Restart bin/dev / rails server if importmap still lists missing controllers.'
  end
end
