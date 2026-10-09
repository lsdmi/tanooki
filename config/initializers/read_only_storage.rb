# frozen_string_literal: true

require 'read_only_storage'

if Rails.configuration.x.active_storage.read_only_services.present?
  ActiveSupport.on_load(:active_storage_blob) do
    require 'active_storage/service/s3_service'
    ActiveStorage::Service::S3Service.prepend(ReadOnlyStorage)
  end
end
