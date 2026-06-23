# frozen_string_literal: true

# Wires SoftDeletable into Action Text / Active Storage and association dependency handling.
module SoftDeletableAssociationHandling
  # Handles belongs_to dependent: :destroy for soft-deletable targets.
  module BelongsTo
    def handle_dependency
      return unless load_target

      case options[:dependent]
      when :destroy then destroy_soft_deletable_target
      else target.send(options[:dependent])
      end
    end

    private

    def destroy_soft_deletable_target
      return unless target.persisted?

      target.destroy
      raise ActiveRecord::Rollback unless dependency_destroyed?(target)
    end

    def dependency_destroyed?(record)
      record.respond_to?(:deleted?) ? record.deleted? : record.destroyed?
    end
  end

  # Handles has_one dependent options for soft-deletable targets.
  module HasOne
    def delete(method = options[:dependent])
      return unless load_target

      case method
      when :delete then target.delete
      when :destroy then destroy_soft_deletable_target
      when :nullify then nullify_soft_deletable_target
      end
    end

    private

    def destroy_soft_deletable_target
      target.destroyed_by_association = reflection
      return unless target.persisted?

      target.destroy
      throw(:abort) unless dependency_destroyed?(target)
    end

    def nullify_soft_deletable_target
      target.update(reflection.foreign_key => nil) if target.persisted?
    end

    def dependency_destroyed?(record)
      record.respond_to?(:deleted?) ? record.deleted? : record.destroyed?
    end
  end

  # Uniqueness checks ignore soft-deleted rows.
  module UniquenessValidator
    def build_relation(klass, *args)
      relation = super
      return relation unless klass.respond_to?(:without_deleted)

      relation.merge(klass.without_deleted)
    end
  end
end

Rails.application.config.to_prepare do
  ActiveRecord::Base.define_singleton_method(:soft_deletable?) { false }
  ActiveRecord::Base.define_method(:soft_deletable?) { false }

  [
    ActionText::RichText,
    ActiveStorage::Attachment,
    ActiveStorage::Blob
  ].each do |model|
    model.include SoftDeletable unless model.include?(SoftDeletable)
  end

  ActiveRecord::Associations::BelongsToAssociation.prepend(SoftDeletableAssociationHandling::BelongsTo)
  ActiveRecord::Associations::HasOneAssociation.prepend(SoftDeletableAssociationHandling::HasOne)

  ActiveRecord::Validations::UniquenessValidator.prepend(SoftDeletableAssociationHandling::UniquenessValidator)
end
