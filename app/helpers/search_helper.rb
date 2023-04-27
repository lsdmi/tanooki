# frozen_string_literal: true

module SearchHelper
  TAG_GROUP_SIZE = 3
  START_POSITION = 5

  def tag_group(size)
    (size - START_POSITION) / TAG_GROUP_SIZE
  end

  def main_column(results)
    size = tag_group(results.size)
    last_position = (size * 2) - 1

    results[(size + START_POSITION)..(last_position + START_POSITION)]
  end

  def right_column(results)
    size = tag_group(results.size)
    start_position = size * 2
    last_position = (size * 3) - 1

    results[(start_position + START_POSITION)..(last_position + START_POSITION)]
  end

  def left_column(results)
    size = tag_group(results.size)
    last_position = size - 1

    results[START_POSITION..(last_position + START_POSITION)]
  end

  def random_size
    [
      'lg:h-[200px]',
      'lg:h-[250px]',
      'lg:h-[300px]'
    ].sample
  end
end
