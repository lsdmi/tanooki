# frozen_string_literal: true

# Replays version 2 HP from battle events alone: start at max, apply each hit, persistent save and heal. +check+
# returns [expected, reported] HP for the events that report it.
class HpLedger
  def initialize(max_hp)
    @max_hp = max_hp
    @hp = max_hp.dup
    @saved = nil
  end

  def check(event)
    case event.type
    when :trait_triggered then save(event.data)
    when :hit then hit(event.data)
    when :healed then heal(event.data)
    when :fainted then [0.0, @hp[event.data[:combatant]]]
    end
  end

  private

  def save(data)
    @saved = data[:combatant] if data[:trait] == 'persistent'
    nil
  end

  def hit(data)
    id = data[:target]
    expected = @saved == id ? [@hp[id], 1.0].min : [@hp[id] - data[:damage], 0.0].max
    @saved = nil
    record(id, expected, data[:hp_left])
  end

  def heal(data)
    id = data[:combatant]
    record(id, [@hp[id] + data[:amount], @max_hp[id]].min, data[:hp_left])
  end

  def record(id, expected, reported)
    @hp[id] = reported
    [expected, reported]
  end
end
