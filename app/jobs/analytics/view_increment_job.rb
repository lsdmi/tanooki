# frozen_string_literal: true

module Analytics
  # Persists a single view count increment off the request path (fiction/chapter show TTFB).
  class ViewIncrementJob < ApplicationJob
    queue_as :default

    MODELS = {
      'Bookshelf' => Bookshelf,
      'Chapter' => Chapter,
      'Fiction' => Fiction,
      'Publication' => Publication,
      'Tale' => Tale,
      'YoutubeVideo' => YoutubeVideo
    }.freeze

    def perform(class_name, record_id)
      klass = MODELS[class_name]
      return unless klass

      increment_views(klass, record_id)
    end

    private

    def increment_views(klass, record_id)
      predicates = ["#{klass.quoted_primary_key} = #{Integer(record_id)}"]
      predicates << 'deleted_at IS NULL' if klass.soft_deletable?

      klass.lease_connection.update(<<~SQL.squish)
        UPDATE #{klass.quoted_table_name}
        SET views = COALESCE(views, 0) + 1
        WHERE #{predicates.join(' AND ')}
      SQL
    end
  end
end
