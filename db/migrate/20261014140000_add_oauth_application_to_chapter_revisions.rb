# frozen_string_literal: true

# Which connected chat stored a revision. A refreshed OAuth token keeps the same application.
class AddOauthApplicationToChapterRevisions < ActiveRecord::Migration[8.1]
  def change
    add_reference :chapter_revisions, :oauth_application, index: true, null: true, after: :api_token_id,
                                                          foreign_key: { on_delete: :nullify }
  end
end
