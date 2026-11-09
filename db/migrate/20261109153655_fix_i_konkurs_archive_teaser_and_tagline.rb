# frozen_string_literal: true

# Replace placeholder teaser and shorten archive tagline for I konkurs SEO copy.
class FixIKonkursArchiveTeaserAndTagline < ActiveRecord::Migration[8.1]
  TEASER = 'Архів: п’ять ориджиналів, переможець і фонд спільноти.'
  TAGLINE = 'Ориджинали, січень–березень 2024. Перший конкурс авторського ранобе на Баці.'

  def up
    Contest.where(slug: 'i-konkurs-ranobe').update_all(
      teaser_text: TEASER,
      tagline: TAGLINE,
      updated_at: Time.current
    )
  end

  def down
    # Irreversible content fix — previous teaser was a placeholder ("Привіт").
  end
end
