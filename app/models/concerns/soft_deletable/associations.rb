# frozen_string_literal: true

module SoftDeletable
  # Hard-deletes soft-deletable associations before really_destroy!.
  module Associations
    extend ActiveSupport::Concern

    private

    def really_destroy_soft_deletable_associations
      soft_deletable_destroy_dependencies.each do |name, reflection|
        really_destroy_association(name, reflection)
      end
    end

    def soft_deletable_destroy_dependencies
      self.class.reflections.select do |_name, reflection|
        reflection.options[:dependent] == :destroy &&
          reflection.klass.respond_to?(:soft_deletable?) &&
          reflection.klass.soft_deletable?
      end
    end

    def really_destroy_association(name, reflection)
      association_data = public_send(name)
      return unless association_data

      if reflection.collection?
        association_data.with_deleted.find_each(&:really_destroy!)
      else
        association_data.really_destroy!
      end
    end
  end
end
