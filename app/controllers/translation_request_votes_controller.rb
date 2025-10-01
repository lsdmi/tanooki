# frozen_string_literal: true

class TranslationRequestVotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_translation_request

  def create
    user_voted = toggle_user_vote
    render_vote_response(user_voted)
  end

  private

  def toggle_user_vote
    existing_vote = find_existing_vote

    if existing_vote
      existing_vote.destroy
      false
    else
      create_new_vote
      true
    end
  end

  def find_existing_vote
    @translation_request.translation_request_votes.find_by(user: current_user)
  end

  def create_new_vote
    @translation_request.translation_request_votes.create(user: current_user)
  end

  def render_vote_response(user_voted)
    render json: {
      votes_count: @translation_request.reload.votes_count,
      user_voted: user_voted
    }
  end

  def set_translation_request
    @translation_request = TranslationRequest.find(params[:translation_request_id])
  end
end
