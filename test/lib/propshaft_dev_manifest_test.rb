# frozen_string_literal: true

require 'test_helper'
require 'propshaft_dev_manifest'

class PropshaftDevManifestTest < ActiveSupport::TestCase
  setup do
    @manifest_path = Rails.root.join("tmp/propshaft-dev-manifest-test-#{Process.pid}.json")
    PropshaftDevManifest.refresh!(@manifest_path)
  end

  teardown do
    @manifest_path.delete if @manifest_path.exist?
  end

  test 'refresh! updates the digest of a build that changes' do
    # A file of this worker's own: rewriting the shared tailwind.css would race the other parallel workers.
    build = Rails.root.join("app/assets/builds/propshaft-dev-manifest-test-#{Process.pid}.css")
    logical_path = build.basename.to_s

    begin
      build.write('a {}')
      # The sweeper ignores future mtimes and Linux CI has 1s resolution, so date the first write back.
      past = 10.seconds.ago.to_time
      File.utime(past, past, build)
      PropshaftDevManifest.refresh!(@manifest_path)
      stale_digest = JSON.parse(@manifest_path.read)[logical_path]['digested_path']

      build.write('b {}')
      PropshaftDevManifest.refresh!(@manifest_path)

      assert_not_equal stale_digest, JSON.parse(@manifest_path.read)[logical_path]['digested_path']
    ensure
      build.delete if build.exist?
      PropshaftDevManifest.refresh!(@manifest_path)
    end
  end

  test 'stale? is true when a new image is not in the manifest' do
    manifest = JSON.parse(@manifest_path.read)
    manifest.delete('baka-telegram-mockup.webp')
    @manifest_path.write(manifest.to_json)

    assert PropshaftDevManifest.stale?(@manifest_path)
  ensure
    PropshaftDevManifest.refresh!(@manifest_path)
  end

  test 'refresh! exposes homepage telegram promo image' do
    helper = Class.new do
      include ActionView::Helpers::AssetUrlHelper
      include Propshaft::Helper
    end.new

    PropshaftDevManifest.refresh!(@manifest_path)

    assert_includes helper.asset_path('baka-telegram-mockup.webp'), 'baka-telegram-mockup'
  end

  test 'stale? is true when Gemfile.lock is newer than the manifest' do
    past = Rails.root.join('Gemfile.lock').mtime - 1
    File.utime(past, past, @manifest_path)

    assert PropshaftDevManifest.stale?(@manifest_path)
  end

  test 'stale? watches top-level javascript files, not only controllers' do
    roots = []
    PropshaftDevManifest.stub(:stale_tree?, ->(root, _mtime) { roots.push(root).empty? }) do
      PropshaftDevManifest.stale?(@manifest_path)
    end

    assert_includes roots, Rails.root.join('app/javascript')
  end

  test 'reload_if_rewritten! drops the cached resolver once the manifest is rewritten elsewhere' do
    assets = Rails.application.assets
    PropshaftDevManifest.reload_if_rewritten!(@manifest_path)
    resolver = assets.resolver
    PropshaftDevManifest.reload_if_rewritten!(@manifest_path)

    assert_same resolver, assets.resolver

    future_mtime = @manifest_path.mtime + 1
    File.utime(future_mtime, future_mtime, @manifest_path)
    PropshaftDevManifest.reload_if_rewritten!(@manifest_path)

    assert_not_same resolver, assets.resolver
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
