# frozen_string_literal: true

module Admin
  module Contests
    # Manual prize → entry assignment and payout tracking (P0 stand-in for formula).
    class AwardsController < ApplicationController
      before_action :authenticate_user!, :verify_user_permissions
      before_action :set_contest

      def create
        @contest.awards.create!(new_award_attributes)
        redirect_to admin_contest_path(@contest), notice: t('admin.contests.awards.notices.created')
      rescue ActiveRecord::RecordInvalid => e
        redirect_to admin_contest_path(@contest), alert: e.record.errors.full_messages.to_sentence
      end

      def update
        award = @contest.awards.find(params.expect(:id))
        award.update!(award_params)
        redirect_to admin_contest_path(@contest), notice: t('admin.contests.awards.notices.updated')
      rescue ActiveRecord::RecordInvalid => e
        redirect_to admin_contest_path(@contest), alert: e.record.errors.full_messages.to_sentence
      end

      private

      def set_contest
        @contest = Contest.find(params.expect(:contest_id))
      end

      def new_award_attributes
        {
          contest_prize: @contest.prizes.find(params.expect(:contest_prize_id)),
          contest_entry: @contest.entries.find(params.expect(:contest_entry_id)),
          awarded_at: Time.current
        }
      end

      def award_params
        permitted = params.expect(contest_award: %i[paid_at payout_note mark_paid])
        attrs = permitted.to_h.symbolize_keys.except(:mark_paid)
        attrs[:paid_at] ||= Time.current if ActiveModel::Type::Boolean.new.cast(permitted[:mark_paid])
        attrs
      end
    end
  end
end
