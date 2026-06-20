# frozen_string_literal: true

# Keeps tmp/propshaft-dev-manifest.json aligned with app/javascript/controllers and
# app/assets/builds (tailwindcss:watch). Without this, Propshaft's Static resolver
# emits stale digested URLs while the asset server rejects them → 404 and no CSS.
module PropshaftDevManifest
  MANIFEST_SUFFIX = 'propshaft-dev-manifest.json'

  module_function

  def refresh_if_stale!
    return unless Rails.env.development?

    manifest_path = Rails.application.config.assets.manifest_path
    return unless manifest_path.to_s.end_with?(MANIFEST_SUFFIX)

    return unless stale?(manifest_path)

    refresh!(manifest_path)
  end

  def refresh!(manifest_path = Rails.application.config.assets.manifest_path)
    assembly = Rails.application.assets
    load_path = assembly.load_path
    load_path.cache_sweeper.execute_if_updated

    manifest_path.dirname.mkpath
    File.write(manifest_path, load_path.manifest.to_json)
    assembly.instance_variable_set(:@resolver, nil)

    manifest_path
  end

  def stale?(manifest_path)
    return true unless manifest_path.exist?

    manifest_mtime = manifest_path.mtime
    stale_tree?(Rails.root.join('app/javascript/controllers'), manifest_mtime) ||
      stale_tree?(Rails.root.join('app/assets/builds'), manifest_mtime)
  end

  def stale_tree?(root, manifest_mtime)
    return false unless root.directory?

    root.glob('**/*').any? { |path| path.file? && path.mtime > manifest_mtime }
  end
end
