# frozen_string_literal: true

module Admin
  # Utilitarian contest CRUD, publish/cancel, preset/duplicate, and results publication.
  class ContestsController < ApplicationController
    include Admin::ContestParams
    include Admin::ContestRuleChanges

    before_action :authenticate_user!, :verify_user_permissions
    before_action :set_contest,
                  only: %i[show edit update destroy publish cancel publish_results duplicate]

    def index
      @contests = Contest.order(announced_at: :desc)
    end

    def show
      @prizes = @contest.prizes.order(:position, :id)
      @awards = @contest.awards.includes(:contest_prize, contest_entry: :fiction)
      @unawarded_entries = @contest.entries.where(status: %w[accepted qualified]).order(:id)
      @readiness = ::Contests::Readiness.call(@contest) if @contest.published_at.blank?
      @unreviewed_after_deadline = @contest.unreviewed_after_deadline?
    end

    def new
      @contest = Contest.new(default_contest_attributes)

      @contest.prizes.build(DEFAULT_PRIZES)
      @contest.jurors.build
    end

    def new_from_preset
      @presets = ::Contests::Preset.all
    end

    def create_from_preset
      contest = ::Contests::CreateFromPreset.call(
        preset: params.expect(:preset_key),
        submissions_open_at: params.expect(:submissions_open_at),
        prize_pool_uah: params.expect(:prize_pool_uah),
        title: params[:title].presence
      )
      redirect_to edit_admin_contest_path(contest), notice: t('admin.contests.notices.created_from_preset')
    rescue ::Contests::Preset::Error, ::Contests::CreateFromPreset::Error, ActiveRecord::RecordInvalid => e
      redirect_to new_from_preset_admin_contests_path, alert: e.message
    end

    def edit
      @contest.prizes.build if @contest.prizes.empty?
      @contest.jurors.build if @contest.jurors.empty?
    end

    def create
      @contest = Contest.new(contest_params)
      if @contest.save
        redirect_to admin_contest_path(@contest), notice: t('admin.contests.notices.created')
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      return render_rule_change_reason_required if rule_change_reason_missing?

      if @contest.update(contest_params)
        append_rule_change!
        redirect_to admin_contest_path(@contest), notice: t('admin.contests.notices.updated')
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @contest.destroy!
      redirect_to admin_contests_path, notice: t('admin.contests.notices.destroyed')
    end

    def publish
      readiness = ::Contests::Readiness.new(@contest)
      return redirect_not_ready(readiness) unless readiness.ready?

      if published?
        return redirect_to(admin_contest_path(@contest), alert: t('admin.contests.notices.already_published'))
      end

      @contest.update!(published_at: Time.current, rules_snapshot: ::Contests::RulesBuilder.snapshot(@contest))
      redirect_to admin_contest_path(@contest), notice: t('admin.contests.notices.published')
    end

    def cancel
      reason = params[:cancel_reason].to_s.strip
      if reason.blank?
        redirect_to admin_contest_path(@contest), alert: t('admin.contests.notices.cancel_reason_required')
        return
      end

      @contest.update!(cancelled_at: Time.current, cancel_reason: reason)
      redirect_to admin_contest_path(@contest), notice: t('admin.contests.notices.cancelled')
    end

    def publish_results
      ::Contests::PublishResults.call(contest: @contest, actor: current_user)
      redirect_to admin_contest_path(@contest), notice: t('admin.contests.results.published')
    rescue ::Contests::PublishResults::Error => e
      redirect_to admin_contest_path(@contest), alert: e.message
    end

    def duplicate
      draft = ::Contests::Duplicate.call(contest: @contest)
      redirect_to edit_admin_contest_path(draft), notice: t('admin.contests.notices.duplicated')
    rescue ::Contests::Duplicate::Error, ActiveRecord::RecordInvalid => e
      redirect_to admin_contest_path(@contest), alert: e.message
    end

    private

    def set_contest
      @contest = Contest.find(params.expect(:id))
    end

    def redirect_not_ready(readiness)
      items = readiness.missing_keys.map { |key| t("admin.contests.readiness.items.#{key}") }.join(', ')
      redirect_to admin_contest_path(@contest), alert: t('admin.contests.notices.not_ready', items:)
    end
  end
end
