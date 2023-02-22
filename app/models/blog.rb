# frozen_string_literal: true

class Blog < Publication
  self.table_name = 'publications'
  default_scope -> { where(type: 'Blog') }
end
