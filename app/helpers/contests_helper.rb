# frozen_string_literal: true

# View helpers for public contest pages and the one-screen submission form.
module ContestsHelper
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

  def contests_publicly_visible?
    Contests::PublicAccess.visible?(current_user)
  end

  # Spacing/type: xl+ is the ideal; smaller breakpoints step down from it.
  def contest_section_label_class
    'border-b border-brand/45 pb-1 text-sm font-semibold text-fg ' \
      'sm:pb-1.5 sm:text-base md:pb-2 md:text-base lg:text-lg xl:pb-2 xl:text-lg 2xl:text-lg'
  end

  def contest_section_label_plain_class
    'text-sm font-semibold text-fg sm:text-base md:text-base lg:text-lg xl:text-lg 2xl:text-lg'
  end

  def contest_section_y_class
    'mt-6 sm:mt-8 md:mt-10 lg:mt-12 xl:mt-16 2xl:mt-16'
  end

  def contest_content_pt_class
    'pt-6 sm:pt-7 md:pt-8 lg:pt-10 xl:pt-14 2xl:pt-14'
  end

  def contest_band_pad_class
    'pt-5 pb-6 sm:pt-6 sm:pb-8 md:pt-8 md:pb-10 lg:pt-10 lg:pb-12 xl:pt-12 xl:pb-16 2xl:pt-12 2xl:pb-16'
  end

  def contest_split_gap_class
    'gap-6 sm:gap-7 md:gap-8 lg:gap-x-8 lg:gap-y-10 xl:gap-x-12 xl:gap-y-12 2xl:gap-x-12'
  end

  def contest_split_rail_class
    'border-t border-line pt-5 sm:pt-6 md:pt-7 lg:border-t-0 lg:border-l lg:pt-0 lg:pl-8 xl:pl-10'
  end

  def contest_archive_dates_line(contest)
    open_at = contest.submissions_open_at
    close_at = contest.submissions_close_at
    return if open_at.blank? || close_at.blank?

    span = contest_month_span(open_at, close_at)
    results_at = contest.results_published_at
    return span if results_at.blank?

    t('contests.show.timeline.archive_line', span:, results: l(results_at.to_date, format: :long))
  end

  def contest_gallery_grid_class(count)
    cols = contest_gallery_column_count(count)
    [
      'mt-2.5 grid grid-cols-2 gap-2 sm:mt-3 sm:gap-2.5 md:mt-3.5 md:gap-3 lg:mt-4 lg:gap-4 xl:mt-4 xl:gap-5 2xl:gap-5',
      GALLERY_SM_COL_CLASS.fetch(cols, 'sm:grid-cols-6')
    ].join(' ')
  end

  def contest_gallery_column_count(count)
    n = count.to_i
    return n if n.between?(1, 5)

    GALLERY_COLUMN_COUNT.fetch(n, 6)
  end

  def contest_month_span(open_at, close_at)
    open_at = open_at.in_time_zone
    close_at = close_at.in_time_zone
    open_label = contest_month_label(open_at)
    close_label = contest_month_label(close_at)
    return "#{open_label}–#{close_label} #{close_at.year}" if open_at.year == close_at.year

    "#{open_label} #{open_at.year}–#{close_label} #{close_at.year}"
  end

  def contest_submit_requirements_line(contest)
    kind = t("contests.kinds.#{contest.kind}").downcase
    parts = [
      contest.requires_new_work? ? t('contests.submit.req.new_kind', kind:) : kind,
      t('contests.submit.req.deadline', date: l(contest.submissions_close_at.to_date, format: :long))
    ]
    volume = contest_submit_volume_parts(contest)
    parts << volume.join(' · ') if volume.any?
    parts.join(' · ')
  end

  def contest_submit_volume_parts(contest)
    volume = []
    volume << t('contests.submit.req.chapters', count: contest.min_chapters) if contest.min_chapters
    if contest.min_words
      volume << t('contests.submit.req.words', count: number_with_delimiter(contest.min_words, delimiter: ' '))
    end
    volume
  end

  def contest_entry_for_fiction(fiction)
    return if fiction.blank?

    fiction.contest_entries.active.includes(:contest).order(submitted_at: :desc).first
  end

  private

  def contest_month_label(time)
    I18n.t('date.standalone_month_names')[time.month].downcase
  end
end
