# frozen_string_literal: true

module Analytics
  # Counts page views in memory and writes them every minute with one UPDATE per model, instead of a job per view.
  # A thread in the web process does the writes. Counts are written before a normal exit (deploys) and before a code
  # reload in development; a killed process loses at most a minute of views. Puma runs single-process, so there is
  # one buffer per container.
  class ViewCounter
    MODELS = %w[Bookshelf Chapter Fiction Publication Tale YoutubeVideo].freeze
    FLUSH_EVERY = 60
    STOP_WAIT = 10
    BATCH_SIZE = 500

    class << self
      def default
        @default ||= new
      end

      def shutdown
        @default&.stop
      end
    end

    def initialize(flush_every: FLUSH_EVERY, logger: Rails.logger, background: !Rails.env.test?)
      @flush_every = flush_every
      @logger = logger
      @background = background
      @mutex = Mutex.new
      @signal = Thread::Queue.new
      @counts = empty_counts
    end

    def add(record)
      model = record.class.name
      return unless MODELS.include?(model)

      @mutex.synchronize do
        @counts[model][record.id] += 1
        @thread = Thread.new { run } if @background && !@thread&.alive?
      end
    end

    def pending
      @mutex.synchronize { @counts.transform_values(&:dup) }
    end

    def flush
      counts = @mutex.synchronize { @counts.tap { @counts = empty_counts } }
      counts.each { |model, views_by_id| write_model(model, views_by_id) }
    end

    # The last write runs in the caller: a dev code reload holds the lock the thread would need to load models.
    def stop
      thread = @mutex.synchronize { @thread.tap { @thread = nil } }
      return unless thread

      @signal << :stop
      thread.join(STOP_WAIT)
      flush
    end

    def clear
      @mutex.synchronize { @counts = empty_counts }
    end

    private

    def empty_counts
      Hash.new { |counts, model| counts[model] = Hash.new(0) }
    end

    def run
      Thread.current.name = 'view-counter'
      flush until @signal.pop(timeout: @flush_every) == :stop
    end

    def write_model(model, views_by_id)
      views_by_id.each_slice(BATCH_SIZE) do |slice|
        update_views(model.constantize, slice)
      rescue StandardError => e
        @logger.error("[ViewCounter] #{model} write failed, keeping #{slice.size} records for the next flush: " \
                      "#{e.class}: #{e.message}")
        restore(model, slice)
      end
    end

    def update_views(klass, slice)
      key = klass.quoted_primary_key
      cases = slice.map { |id, views| "WHEN #{Integer(id)} THEN #{Integer(views)}" }.join(' ')

      klass.with_connection do |connection|
        connection.update(<<~SQL.squish)
          UPDATE #{klass.quoted_table_name}
          SET views = COALESCE(views, 0) + CASE #{key} #{cases} END
          WHERE #{update_predicates(klass, slice.map(&:first)).join(' AND ')}
        SQL
      end
    end

    def update_predicates(klass, ids)
      predicates = ["#{klass.quoted_primary_key} IN (#{ids.map { |id| Integer(id) }.join(', ')})"]
      predicates << 'deleted_at IS NULL' if klass.soft_deletable?
      predicates
    end

    def restore(model, slice)
      @mutex.synchronize { slice.each { |id, views| @counts[model][id] += views } }
    end
  end
end
