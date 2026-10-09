# frozen_string_literal: true

# Per-request attributes for the token API. The web session does not use this.
class Current < ActiveSupport::CurrentAttributes
  attribute :user, :api_token
end
