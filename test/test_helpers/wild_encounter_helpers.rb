# frozen_string_literal: true

module WildEncounterHelpers
  # Forces the next wild roll to succeed with a given species, then loads the pop-up frame as the browser would.
  def with_guaranteed_encounter(pokemon)
    pokemon.sprite.attach(io: file_fixture('cover_valid.webp').open, filename: "#{pokemon.slug}.webp")

    Pokemons::WildCatchPool.stub(:sample_id, pokemon.id) do
      with_winning_rolls(skip_delay: true) do
        yield
        get css_select('turbo-frame#catch-pokemon').first['src']
      end
    end
  end

  # Every 2% roll wins; skip_delay also ignores the encounter delay (a new guest otherwise waits it).
  def with_winning_rolls(skip_delay: false, &)
    build = Pokemons::WildCatch.method(:new)
    winning = lambda { |**kwargs|
      build.call(**kwargs).tap do |service|
        service.define_singleton_method(:rand) { |*| 0.0 }
        next unless skip_delay

        service.define_singleton_method(:eligible?) { true }
        service.define_singleton_method(:encountered_recently?) { false }
      end
    }

    Pokemons::WildCatch.stub(:new, winning, &)
  end
end
