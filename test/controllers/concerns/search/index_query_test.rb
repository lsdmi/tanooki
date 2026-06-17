# frozen_string_literal: true

require 'test_helper'

class SearchIndexQueryTest < ActiveSupport::TestCase
  class QueryHost
    include Search::IndexQuery

    attr_accessor :params

    def initialize(params)
      @params = params
    end
  end

  setup do
    @host = QueryHost.new(ActionController::Parameters.new(search: ['test']))
  end

  test 'fiction_search chains cover attachment and blob preload' do
    search_args = @host.send(:fiction_search)

    assert_equal [:includes, { cover_attachment: :blob }], search_args[4..]
  end

  test 'preloaded fiction covers avoid extra queries per record' do
    fiction = fictions(:one)
    attach_cover(fiction) unless fiction.cover.attached?

    loaded = Fiction.where(id: fiction.id).includes(cover_attachment: :blob).to_a

    assert_queries_count(0) do
      loaded.each do |record|
        record.cover.blob if record.cover.attached?
      end
    end
  end

  private

  def attach_cover(fiction)
    fiction.cover.attach(
      io: Rails.root.join('app/assets/images/logo-default.svg').open,
      filename: 'logo-default.svg',
      content_type: 'image/svg+xml'
    )
  end
end
