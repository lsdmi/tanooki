# frozen_string_literal: true

module Contests
  # Submit an existing fiction, or withdraw from a contest (CONTESTS.md 0.6).
  class ParticipationsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_contests_public_access!
    before_action :load_contest!
    before_action :load_fiction!, only: %i[new create]
    before_action :load_entry!, only: :destroy

    rate_limit to: 10, within: 1.minute, only: :create,
               by: -> { current_user.id },
               with: -> { redirect_to contest_path(@contest), alert: t('contests.submit.rate_limited') }

    def new
      @form = ParticipationForm.new(**form_attributes)
      render :new
    end

    def create
      @form = ParticipationForm.new(**form_attributes, params: participation_params)
      if @form.save
        redirect_to contest_path(@contest, anchor: 'my-entry'), notice: t('contests.submit.success')
      else
        render :new, status: :unprocessable_content
      end
    end

    def destroy
      Contests::WithdrawEntry.call(entry: @entry, actor: current_user)
      redirect_to contest_path(@contest), notice: t('contests.participation.withdrawn')
    rescue Contests::WithdrawEntry::Error => e
      redirect_to contest_path(@contest, anchor: 'my-entry'), alert: e.message
    end

    private

    def require_contests_public_access!
      raise ActiveRecord::RecordNotFound unless Contests::PublicAccess.visible?(current_user)
    end

    def load_contest!
      @contest = Contest.friendly.find(params.expect(:contest_slug))
      raise ActiveRecord::RecordNotFound if @contest.draft?
    end

    def load_fiction!
      @fiction = Fiction.friendly.find(params.expect(:fiction_id))
    end

    def load_entry!
      @entry = Contests::ShowPresenter.new(contest: @contest, user: current_user).my_entry
      raise ActiveRecord::RecordNotFound if @entry.blank?
    end

    def form_attributes
      { user: current_user, contest: @contest, fiction: @fiction }
    end

    def participation_params
      params.fetch(:participation, {}).permit(:ai_usage, :ai_note, :rules_accepted).to_h.symbolize_keys
    end
  end
end
