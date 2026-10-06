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

  test 'refresh! updates tailwind digest when builds change' do
    # Parallel workers share app/assets/builds/tailwind.css; mutating it races the suite.
    skip 'shared tailwind.css is unsafe under parallel workers' if ENV['TEST_ENV_NUMBER'].present?

    tailwind_path = Rails.root.join('app/assets/builds/tailwind.css')
    original = tailwind_path.read
    stale_digest = JSON.parse(@manifest_path.read)['tailwind.css']['digested_path']

    begin
      tailwind_path.write("#{original} ")
      PropshaftDevManifest.refresh!(@manifest_path)

      assert_not_equal stale_digest, JSON.parse(@manifest_path.read)['tailwind.css']['digested_path']
    ensure
      tailwind_path.write(original)
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
