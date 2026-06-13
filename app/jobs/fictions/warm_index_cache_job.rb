# frozen_string_literal: true

module Fictions
  # Preloads fiction index cache keys so /fictions/ avoids cold-cache TTFB spikes.
  class WarmIndexCacheJob < ApplicationJob
    queue_as :default

    def perform
      IndexVariablesManager.warm_index_caches!
      FictionIndexPresenter.warm_caches!
    end
  end
end
