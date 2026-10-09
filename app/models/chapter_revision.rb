# frozen_string_literal: true

# The chapter body and title as they were before an API change.
class ChapterRevision < ApplicationRecord
  belongs_to :chapter
  belongs_to :user
  belongs_to :api_token, optional: true

  # A chapter subtitle may be blank. The snapshot keeps that title, including an empty one.
end
