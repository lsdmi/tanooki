# frozen_string_literal: true

# Counts SQL for a request and fails when it grows past a budget (Stream 3 guardrails).
module QueryBudgetHelper
  RICH_TEXT_SQL = /action_text_rich_texts/i

  def count_queries(&)
    counter = ActiveRecord::Assertions::QueryAssertions::SQLCounter.new
    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record', &)
    counter.log
  end

  def assert_queries_at_most(max, message = nil, &)
    queries = count_queries(&)

    assert_operator(
      queries.size, :<=, max,
      message || "#{queries.size} queries (budget #{max}).\n#{queries.join("\n")}"
    )
    queries
  end

  def assert_list_page_query_budget(max, &)
    queries = assert_queries_at_most(max, &)
    rich = queries.grep(RICH_TEXT_SQL)

    assert_empty rich, "list pages must not load Action Text bodies:\n#{rich.join("\n")}"
  end
end
