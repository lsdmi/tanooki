# frozen_string_literal: true

# One-off: confirms DO db-migrate PRE_DEPLOY job (no schema change). Safe to keep or remove later.
class VerifyDoPreDeployMigrate < ActiveRecord::Migration[8.0]
  def up
    say 'DO PRE_DEPLOY db:migrate verified', true
  end

  def down
    # metadata only
  end
end
