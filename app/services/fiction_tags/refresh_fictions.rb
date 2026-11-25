# frozen_string_literal: true

module FictionTags
  # Brings works up to date after a tag on them changed (rename, hide, 18+, delete, merge).
  # Saving each work bumps updated_at, which expires fragments keyed on it, and queues its Searchkick reindex,
  # so search picks up the new tag names.
  module RefreshFictions
    def self.call(fiction_ids)
      Fiction.where(id: Array(fiction_ids).uniq).find_each do |fiction|
        fiction.updated_at = Time.current
        fiction.save!(validate: false)
      end
    end
  end
end
