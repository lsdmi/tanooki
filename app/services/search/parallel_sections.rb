# frozen_string_literal: true

module Search
  # Runs independent Searchkick section loaders concurrently on filter=all.
  # Each block gets its own AR connection; wall clock ≈ slowest leg, not the sum.
  class ParallelSections
    def self.call(sections)
      new(sections).call
    end

    def initialize(sections)
      @sections = sections
    end

    def call
      errors = Concurrent::Array.new
      results = Concurrent::Map.new

      futures = @sections.map do |name, work|
        Concurrent::Promises.future { run_section(name, work, results, errors) }
      end
      Concurrent::Promises.zip(*futures).wait!
      raise errors.first if errors.any?

      @sections.each_key.with_object({}) { |name, hash| hash[name] = results[name] }
    end

    private

    def run_section(name, work, results, errors)
      ActiveRecord::Base.connection_pool.with_connection do
        results[name] = work.call
      rescue StandardError => e
        errors << e
      end
    end
  end
end
