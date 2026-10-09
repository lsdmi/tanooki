# frozen_string_literal: true

# Development runs on a copy of the production database, so its blobs keep service_name "digitalocean": Active Storage
# would upload variants to the production bucket and delete production objects when a dev record is purged. Prepended
# to the S3 service, it refuses every write to the services in config.x.active_storage.read_only_services; downloads
# and URLs work as before.
module ReadOnlyStorage
  class WriteRefused < ActiveStorage::Error; end

  WRITES = %i[upload compose delete delete_prefixed update_metadata url_for_direct_upload].freeze

  def self.covers?(service_name)
    Array(Rails.configuration.x.active_storage.read_only_services).map(&:to_s).include?(service_name.to_s)
  end

  WRITES.each do |method_name|
    define_method(method_name) do |*args, **options, &block|
      raise WriteRefused, "#{name} is read-only in #{Rails.env} (#{method_name})" if ReadOnlyStorage.covers?(name)

      super(*args, **options, &block)
    end
  end
end
