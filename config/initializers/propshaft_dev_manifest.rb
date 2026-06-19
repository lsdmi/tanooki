# frozen_string_literal: true

# Propshaft dev manifest (tmp/propshaft-dev-manifest.json) powers digested /assets URLs and
# importmap controller pins. Refresh when it is missing or JS controllers change so new
# Stimulus files work without running assets:precompile or a manual manifest edit.
if Rails.env.development?
  Rails.application.config.after_initialize do
    manifest_path = Rails.application.config.assets.manifest_path
    next unless manifest_path.to_s.end_with?('propshaft-dev-manifest.json')

    controllers_root = Rails.root.join('app/javascript/controllers')
    stale =
      !manifest_path.exist? ||
      controllers_root.glob('**/*').any? { |path| path.file? && path.mtime > manifest_path.mtime }

    next unless stale

    load_path = Rails.application.assets.load_path
    manifest_path.dirname.mkpath
    File.write(manifest_path, load_path.manifest.to_json)
  end
end
