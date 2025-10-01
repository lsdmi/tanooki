class ResetTranslationRequestVotesCounterCache < ActiveRecord::Migration[8.0]
  def up
    # Reset counter cache for all existing translation requests
    TranslationRequest.find_each do |translation_request|
      votes_count = translation_request.translation_request_votes.count
      translation_request.update_column(:votes_count, votes_count)
    end
  end

  def down
    # No need to rollback counter cache reset
  end
end
