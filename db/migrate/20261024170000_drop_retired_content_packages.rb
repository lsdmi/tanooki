# frozen_string_literal: true

# The first package menu was replaced the same day. Retired keys no longer match a package.
class DropRetiredContentPackages < ActiveRecord::Migration[8.1]
  KNOWN = %w[romance_bl shelves another_world heavens lights_on].freeze

  def up
    quoted = KNOWN.map { |key| connection.quote(key) }.join(', ')
    execute "DELETE FROM user_hidden_packages WHERE package_key NOT IN (#{quoted})"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
