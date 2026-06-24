# frozen_string_literal: true

require 'test_helper'
require 'propshaft_dev_manifest'

class PropshaftDevManifestTest < ActiveSupport::TestCase
  setup do
    @manifest_path = Rails.application.config.assets.manifest_path
    PropshaftDevManifest.refresh!(@manifest_path)
  end

  test 'refresh! updates tailwind digest when builds change' do
    tailwind_path = Rails.root.join('app/assets/builds/tailwind.css')
    stale_digest = JSON.parse(@manifest_path.read)['tailwind.css']['digested_path']

    tailwind_path.open('a') { |file| file.write(' ') }
    PropshaftDevManifest.refresh!(@manifest_path)

    assert_not_equal stale_digest, JSON.parse(@manifest_path.read)['tailwind.css']['digested_path']
  ensure
    tailwind_path.open('a') { |file| file.write("\b") if file.size.positive? }
    PropshaftDevManifest.refresh!(@manifest_path)
  end

  test 'stale? is true when tailwind build is newer than manifest' do
    tailwind_path = Rails.root.join('app/assets/builds/tailwind.css')
    PropshaftDevManifest.refresh!(@manifest_path)

    # Linux CI uses 1s mtime resolution; bump past manifest so stale? sees the change.
    future_mtime = @manifest_path.mtime + 1
    File.utime(future_mtime, future_mtime, tailwind_path)

    assert PropshaftDevManifest.stale?(@manifest_path)
  ensure
    PropshaftDevManifest.refresh!(@manifest_path)
  end
end
