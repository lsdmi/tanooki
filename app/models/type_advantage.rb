# frozen_string_literal: true

require 'yaml'

class TypeAdvantage
  def self.load
    YAML.load_file(Rails.root.join('config', 'type_advantage.yml'))
  end

  def self.effectiveness(attacking_type, defending_type)
    type_advantage = load
    type_advantage[attacking_type][defending_type]
  end
end
