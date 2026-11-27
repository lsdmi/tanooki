# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class FictionsControllerTest < ActionDispatch::IntegrationTest
      include MemoryCacheHelper

      OLD_KEYS = %w[alternative_title cover_url description english_title reference title].freeze

      test 'should get index' do
        get api_v1_fictions_url

        assert_response :success
      end

      test 'every fiction carries its slug and the old keys' do
        get api_v1_fictions_url

        entries = response.parsed_body

        assert_not_empty entries
        assert(entries.all? { |entry| (OLD_KEYS + %w[slug hikka_slug]).all? { |key| entry.key?(key) } })
        assert_equal Fiction.pluck(:slug).sort, entries.pluck('slug').sort
      end

      test 'reference stays a fiction URL string' do
        get api_v1_fictions_url

        assert(response.parsed_body.all? { |entry| entry['reference'].match?(%r{\Ahttps?://.+/fictions/.+}) })
      end

      test 'hikka_slug is given when set and null when not' do
        fictions(:one).update_column(:hikka_slug, 'guimi-zhi-zhu-7059fd')
        fictions(:two).update_column(:hikka_slug, nil)

        get api_v1_fictions_url

        by_slug = response.parsed_body.index_by { |entry| entry['slug'] }

        assert_equal 'guimi-zhi-zhu-7059fd', by_slug.fetch(fictions(:one).slug)['hikka_slug']
        assert_nil by_slug.fetch(fictions(:two).slug).fetch('hikka_slug')
      end

      test 'deleted fictions are not listed' do
        fictions(:two).destroy

        get api_v1_fictions_url

        assert_not_includes response.parsed_body.pluck('slug'), fictions(:two).slug
      end

      test 'a changed Hikka slug shows in the next response although the list is cached' do
        with_memory_cache do
          get api_v1_fictions_url

          assert_nil hikka_slug_of(fictions(:one))

          FakeHikkaLookup.reset!
          fiction = fictions(:one)
          ::Fictions::HikkaLookup.stub(:new, ->(slug) { FakeHikkaLookup.new(slug) }) do
            fiction.update!(hikka_slug: 'guimi-zhi-zhu-7059fd')
          end
          get api_v1_fictions_url

          assert_equal 'guimi-zhi-zhu-7059fd', hikka_slug_of(fiction)
        end
      end

      private

      def hikka_slug_of(fiction)
        response.parsed_body.find { |entry| entry['slug'] == fiction.slug }['hikka_slug']
      end
    end
  end
end
