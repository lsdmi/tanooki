# frozen_string_literal: true

module Fictions
  class Merge
    # Slugs from `bin/rails fictions:merge[source_slug,target_slug]`.
    class Arguments
      def self.for(args)
        {
          source: Fiction.with_deleted.find_by!(slug: args.fetch(:source_slug)),
          target: Fiction.find_by!(slug: args.fetch(:target_slug)),
          admin: User.where(admin: true).order(:id).first!
        }
      end
    end
  end
end
