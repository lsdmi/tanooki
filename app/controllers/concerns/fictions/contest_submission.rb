# frozen_string_literal: true

module Fictions
  # Contest-mode new/create on FictionsController (CONTESTS.md 0.6 / 8.5).
  module ContestSubmission
    extend ActiveSupport::Concern

    included do
      rate_limit to: 10, within: 1.minute, only: :create,
                 if: -> { contest_param.present? },
                 by: -> { current_user&.id || request.remote_ip },
                 with: lambda {
                   redirect_to new_fiction_path(contest: contest_param), alert: t('contests.submit.rate_limited')
                 }
    end

    private

    def contest_param
      params[:contest].presence || params.dig(:fiction, :contest).presence
    end

    def contest_mode?
      contest_param.present?
    end

    def load_contest_for_submission!
      raise ActiveRecord::RecordNotFound unless Contests::PublicAccess.visible?(current_user)

      @contest = Contest.friendly.find(contest_param)
      raise ActiveRecord::RecordNotFound if @contest.draft?
    end

    def redirect_if_already_entered!
      entry = Contests::ShowPresenter.new(contest: @contest, user: current_user).my_entry
      return if entry.blank? || entry.rejected? || entry.withdrawn?

      redirect_to contest_path(@contest, anchor: 'my-entry')
    end

    def build_contest_submission(param_hash = {})
      Contests::SubmissionForm.new(user: current_user, contest: @contest, params: param_hash)
    end

    def contest_submission_params
      raw = params.fetch(:fiction, {}).permit(
        :title, :description, :content_rating, :cover, :ai_usage, :ai_note, :rules_accepted
      )
      raw[:cover] = Fictions::CoverUploadNormalizer.call(raw[:cover]) if raw[:cover].present?
      raw.to_h.symbolize_keys
    rescue Fictions::CoverUploadNormalizer::Error => e
      @cover_normalize_error = e.message
      raw.to_h.symbolize_keys.except(:cover)
    end

    def render_contest_form(status: :ok)
      @submission ||= build_contest_submission
      values = @submission.params || {}
      @fiction = Fiction.new(
        title: values[:title],
        description: values[:description],
        content_rating: values[:content_rating]
      )
      render 'fictions/contest_new', status:
    end

    def start_contest_submission
      load_contest_for_submission!
      redirect_if_already_entered!
      return if performed?

      @submission = build_contest_submission
      render_contest_form
    end

    def create_contest_submission
      load_contest_for_submission!
      redirect_if_already_entered!
      return if performed?

      @submission = build_contest_submission(contest_submission_params)
      return render_contest_form(status: :unprocessable_content) unless save_contest_submission

      redirect_to contest_path(@contest, anchor: 'my-entry'), notice: t('contests.submit.success')
    end

    def save_contest_submission
      if @cover_normalize_error
        @submission.errors.add(:cover, @cover_normalize_error)
        return false
      end

      @submission.save
    end
  end
end
