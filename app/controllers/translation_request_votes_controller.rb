# frozen_string_literal: true

class TranslationRequestVotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_translation_request

  def create
    # Find existing vote
    translation_request_vote = @translation_request.translation_request_votes
                                                   .find_by(user: current_user)

    # If user already voted, remove the vote (toggle)
    if translation_request_vote
      translation_request_vote.destroy
      user_voted = false
    else
      # Create new upvote
      translation_request_vote = @translation_request.translation_request_votes
                                                     .build(user: current_user)
      translation_request_vote.save
      user_voted = true
    end

    # Return updated vote counts
    render json: {
      votes_count: @translation_request.reload.votes_count,
      user_voted: user_voted
    }
  end

  private

  def set_translation_request
    @translation_request = TranslationRequest.find(params[:translation_request_id])
  end
end
