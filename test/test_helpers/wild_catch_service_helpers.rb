# frozen_string_literal: true

# Drives Pokemons::WildCatch directly: #roll is the page view, #show the pop-up frame request. Needs @session and
# @pokemon.
module WildCatchServiceHelpers
  private

  def wild_catch(user:, dice: 0.0)
    Pokemons::WildCatch.new(session: @session, user:).tap do |wild|
      wild.define_singleton_method(:rand) { |*| dice }
    end
  end

  def roll(user:, dice: 0.0)
    wild_catch(user:, dice:).roll
  end

  def show(user:, ticket: :roll)
    ticket = roll(user:) if ticket == :roll
    Pokemons::WildCatchPool.stub(:sample_id, @pokemon.id) { wild_catch(user:).call(ticket) }
  end
end
