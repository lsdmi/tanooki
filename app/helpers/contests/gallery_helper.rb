# frozen_string_literal: true

module Contests
  # Column math for contest results/works cover grids.
  module GalleryHelper
    # sm+ columns for results/works: 1–5 in one row, then fold into even rows.
    # sm and md share the same column count (no jump at md).
    GALLERY_SM_COL_CLASS = {
      1 => 'sm:mx-auto sm:max-w-[12.5rem] sm:grid-cols-1',
      2 => 'sm:mx-auto sm:max-w-[26rem] sm:grid-cols-2',
      3 => 'sm:mx-auto sm:max-w-[40rem] sm:grid-cols-3',
      4 => 'sm:grid-cols-4',
      5 => 'sm:grid-cols-5',
      6 => 'sm:grid-cols-6'
    }.freeze

    # Counts above 5 fold into even rows (then default to 6).
    GALLERY_COLUMN_COUNT = {
      6 => 3, 7 => 4, 8 => 4, 9 => 3, 10 => 5,
      11 => 4, 12 => 4, 13 => 5, 14 => 5, 15 => 5
    }.freeze

    GALLERY_BASE_CLASS =
      'mt-2.5 grid gap-2 sm:mt-3 sm:gap-2.5 md:mt-3.5 md:gap-3 ' \
      'lg:mt-4 lg:gap-4 xl:mt-4 xl:gap-5 2xl:gap-5'

    def contest_gallery_grid_class(count)
      n = count.to_i
      [
        "#{GALLERY_BASE_CLASS} #{contest_gallery_phone_cols(n)}",
        GALLERY_SM_COL_CLASS.fetch(contest_gallery_column_count(n), 'sm:grid-cols-6'),
        ('xl:mx-0 xl:max-w-none xl:grid-cols-6' if n == 6)
      ].compact.join(' ')
    end

    def contest_gallery_column_count(count)
      n = count.to_i
      return n if n.between?(1, 5)

      GALLERY_COLUMN_COUNT.fetch(n, 6)
    end

    private

    def contest_gallery_phone_cols(count)
      return 'grid-cols-3' if count >= 3
      return 'grid-cols-2' if count == 2

      'grid-cols-1'
    end
  end
end
