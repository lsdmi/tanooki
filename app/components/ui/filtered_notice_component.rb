# frozen_string_literal: true

module Ui
  # One line on a list the reader's content settings shortened, with a link to change them.
  class FilteredNoticeComponent < ViewComponent::Base
    def initialize(change_path:, count: nil)
      super()
      @count = count
      @change_path = change_path
    end

    def render?
      @count.nil? || @count.to_i.positive?
    end

    private

    attr_reader :change_path

    def message
      return t('content_filters.some_hidden') if @count.nil?

      t('content_filters.hidden_count', count: @count)
    end
  end
end
