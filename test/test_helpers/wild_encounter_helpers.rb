# frozen_string_literal: true

# Forces the next wild roll to succeed with a given species, so the pop-up renders on the page.
module WildEncounterHelpers
  def with_guaranteed_encounter(pokemon, &)
    pokemon.sprite.attach(io: file_fixture('cover_valid.webp').open, filename: "#{pokemon.slug}.webp")
    build = Pokemons::WildCatch.method(:new)
    certain = lambda { |**kwargs|
      build.call(**kwargs).tap { |service| service.define_singleton_method(:catch_rate) { 1 } }
    }

    Pokemons::WildCatchPool.stub(:sample_id, pokemon.id) do
      Pokemons::WildCatch.stub(:new, certain, &)
    end
  end
end
