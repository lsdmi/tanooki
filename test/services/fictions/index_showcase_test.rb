# frozen_string_literal: true

require 'test_helper'

module Fictions
  class IndexShowcaseTest < ActiveSupport::TestCase
    setup do
      Rails.cache.delete(IndexShowcase::CACHE_KEY)
      @fiction = fictions(:one)
      @fiction.scanlator_ids = @fiction.scanlators.ids
      @fiction.update!(short_description: 'Коротко про твір для слайда вітрини')
    end

    test 'samples a fiction with a banner and a short description' do
      ids = with_pool { IndexShowcase.for_index.map(&:id) }

      assert_equal [@fiction.id], ids
    end

    test 'never samples a licensed work' do
      license!
      showcase = with_pool { IndexShowcase.for_index }

      assert_empty showcase
    end

    test 'drops a work licensed after its id was cached' do
      with_pool { IndexShowcase.for_index.load }
      license!
      showcase = with_pool { IndexShowcase.for_index }

      assert_empty showcase
    end

    private

    def with_pool(&)
      IndexVariablesManager.stub(:latest_updates_ids_for_badges, [@fiction.id]) do
        IndexVariablesManager.stub(:most_reads_ids_for_badges, []) do
          IndexVariablesManager.stub(:popular_novelty_ids_for_badges, [], &)
        end
      end
    end

    def license!
      @fiction.update!(licensed_at: 1.day.ago, license_publisher: 'Видавництво Тест')
    end
  end
end
