# frozen_string_literal: true

# Public contests hub and contest page.
class ContestsController < ApplicationController
  before_action :require_contests_public_access!

  def index
    @hub = Contests::HubPresenter.new
    preload_contest_cover(@hub.featured)
  end

  def show
    @contest = Contest.friendly.find(params.expect(:slug))
    preview_draft_contest! if @contest.draft?
    preload_contest_cover(@contest)
    @presenter = Contests::ShowPresenter.new(contest: @contest, user: current_user)
    preload_my_entry_fiction(@presenter)
    @comments = @contest.comments.parents.includes(:user, :rich_text_content)
    @comment = Comment.new
  end

  private

  def require_contests_public_access!
    raise ActiveRecord::RecordNotFound unless Contests::PublicAccess.visible?(current_user)
  end

  def preview_draft_contest!
    raise ActiveRecord::RecordNotFound unless current_user&.admin?

    Contests::Readiness.new(@contest).mark_previewed!
  end

  def preload_contest_cover(contest)
    return if contest.blank?
    # Draft show hides every section (incl. hero), so a cover preload would be unused.
    return if contest.draft?

    ActiveRecord::Associations::Preloader.new(
      records: [contest],
      associations: { cover_attachment: :blob }
    ).call
  end

  def preload_my_entry_fiction(presenter)
    entry = presenter.my_entry
    return if entry.blank?

    ActiveRecord::Associations::Preloader.new(records: [entry], associations: :fiction).call
  end
end
