# frozen_string_literal: true

module Meta
  # Reads controller/view assigns without @-prefixed instance variables in helpers.
  module AssignsHelper
    private

    def meta_assign(name)
      instance_variable_get(:"@#{name}")
    end

    def meta_assign_persisted?(name)
      record = meta_assign(name)
      record.present? && record.persisted?
    end

    def meta_assign_persisted(name)
      record = meta_assign(name)
      record if record&.persisted?
    end
  end
end
