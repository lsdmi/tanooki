# frozen_string_literal: true

module Contests
  # Resolves the primary and secondary button for a presenter's phase and role from ShowMatrix.
  class ShowActions
    include Rails.application.routes.url_helpers

    JUDGING_PHASES = %i[judging awaiting_results].freeze
    ANCHORS = { my_entry: 'my-entry', cancellation: 'cancelled' }.freeze

    def initialize(presenter)
      @presenter = presenter
    end

    def primary
      build(matrix_row.first)
    end

    def secondary
      build(matrix_row.second)
    end

    private

    attr_reader :presenter

    delegate :contest, :phase, :role, :my_entry, :user, to: :presenter

    def matrix_row
      key = JUDGING_PHASES.include?(phase) ? :judging : phase
      ShowMatrix::MATRIX.fetch(key) { ShowMatrix::MATRIX.fetch(:announced) }.fetch(role)
    end

    def build(name)
      return if name.blank?

      definition = ShowMatrix::ACTIONS.fetch(name)
      href = href_for(definition[:target])
      return if href.blank?

      { label_key: "contests.show.actions.#{name}", label_args: label_args(name), href:, kind: definition[:kind] }
    end

    def label_args(_name)
      {}
    end

    def href_for(target)
      case target
      when :telegram then ApplicationController.helpers.telegram_site_url
      when :join then join_href
      when :add_chapter then add_chapter_href
      when :admin_edit then edit_admin_contest_path(contest)
      when :admin_entries then admin_contest_entries_path(contest)
      when :admin_show then admin_contest_path(contest)
      else "##{ANCHORS.fetch(target, target.to_s)}"
      end
    end

    def join_href
      path = new_fiction_path(contest: contest.slug)
      return path if user.present?

      new_user_session_path(return_to: path)
    end

    def add_chapter_href
      fiction = my_entry&.fiction
      fiction ? new_chapter_path(fiction: fiction.slug) : "##{ANCHORS.fetch(:my_entry)}"
    end
  end
end
