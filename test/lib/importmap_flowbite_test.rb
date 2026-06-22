# frozen_string_literal: true

require 'test_helper'

class ImportmapFlowbiteTest < ActiveSupport::TestCase
  FLOWBITE_VERSION = '3.1.2'

  test 'flowbite is pinned to vendor javascript not CDN' do
    importmap = Rails.root.join('config/importmap.rb').read

    assert_includes importmap, "pin 'flowbite', to: 'flowbite.turbo.min.js'"
    assert_not_includes importmap, 'cdn.jsdelivr.net/npm/flowbite'
  end

  test 'flowbite vendor file exists and documents version' do
    vendor_path = Rails.root.join('vendor/javascript/flowbite.turbo.min.js')

    assert_path_exists vendor_path
    assert_operator vendor_path.size, :>, 100_000

    importmap = Rails.root.join('config/importmap.rb').read

    assert_includes importmap, FLOWBITE_VERSION
  end
end
