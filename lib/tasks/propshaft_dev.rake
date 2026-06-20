# frozen_string_literal: true

namespace :assets do
  desc 'Refresh tmp/propshaft-dev-manifest.json (new Stimulus controllers, dev digests)'
  task refresh_dev_manifest: :environment do
    abort 'assets:refresh_dev_manifest is for development only' unless Rails.env.development?

    path = PropshaftDevManifest.refresh!

    puts "Updated #{path}"
    puts 'Restart bin/dev / rails server if importmap still lists missing controllers.'
  end
end
