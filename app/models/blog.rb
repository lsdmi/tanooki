# frozen_string_literal: true

class Blog < Publication
  self.table_name = 'publications'
  default_scope -> { where(type: 'Blog') }

  scope :by_current_user, -> { where(user_id: current_user.id) }
end
