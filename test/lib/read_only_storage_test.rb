# frozen_string_literal: true

require 'test_helper'

class ReadOnlyStorageTest < ActiveSupport::TestCase
  class FakeService < ActiveStorage::Service
    prepend ReadOnlyStorage

    def upload(*) = :uploaded
    def delete(*) = :deleted
    def download(*) = :downloaded
  end

  setup do
    @configured = Rails.configuration.x.active_storage.read_only_services
    Rails.configuration.x.active_storage.read_only_services = %w[digitalocean]
  end

  teardown do
    Rails.configuration.x.active_storage.read_only_services = @configured
  end

  test 'a read-only service refuses writes and still reads' do
    service = fake_service('digitalocean')

    assert_raises(ReadOnlyStorage::WriteRefused) { service.upload('key', StringIO.new('x'), checksum: nil) }
    assert_raises(ReadOnlyStorage::WriteRefused) { service.delete('key') }
    assert_equal :downloaded, service.download('key')
  end

  test 'any other service writes as usual' do
    service = fake_service('local')

    assert_equal %i[uploaded deleted], [service.upload('key', StringIO.new('x')), service.delete('key')]
  end

  test 'a blob on a read-only service gets no variant' do
    image = ActiveStorage::Blob.new(content_type: 'image/png', service_name: 'digitalocean')

    assert_not Attachments::VariantProcessing.processable?(image)
  end

  private

  def fake_service(name)
    FakeService.new.tap { |service| service.name = name }
  end
end
