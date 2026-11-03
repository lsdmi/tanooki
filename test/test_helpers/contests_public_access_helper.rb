# frozen_string_literal: true

# Temporarily treats contests as publicly listed (post-launch) inside a block.
module ContestsPublicAccessHelper
  def with_contests_listed(&)
    Contests::PublicAccess.stub(:listed?, true, &)
  end
end

ActiveSupport.on_load(:active_support_test_case) { include ContestsPublicAccessHelper }
ActiveSupport.on_load(:action_dispatch_integration_test) { include ContestsPublicAccessHelper }
