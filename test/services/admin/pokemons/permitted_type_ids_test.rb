# frozen_string_literal: true

require 'test_helper'

module Admin
  module Pokemons
    class PermittedTypeIdsTest < ActiveSupport::TestCase
      test 'returns only existing pokemon type ids' do
        valid_id = pokemon_types(:one).id

        assert_equal [valid_id], PermittedTypeIds.filter([valid_id, 999_999])
      end

      test 'returns empty array for blank input' do
        assert_empty PermittedTypeIds.filter(nil)
        assert_empty PermittedTypeIds.filter([])
        assert_empty PermittedTypeIds.filter(['', nil])
      end
    end
  end
end
