# frozen_string_literal: true

class FavouriteTranslatorsFinder
  def initialize(readings)
    @readings = readings
  end

  def find
    scanlators = @readings.flat_map { |reading| reading.fiction.scanlators }
    scanlator_counts = scanlators.each_with_object(Hash.new(0)) { |scanlator, counts| counts[scanlator] += 1 }
    scanlator_counts.sort_by { |_, count| -count }.first(2).map(&:first)
  end
end
