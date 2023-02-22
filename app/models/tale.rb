# frozen_string_literal: true

class Tale < Publication
  self.table_name = 'publications'
  default_scope -> { where(type: 'Tale') }
end
