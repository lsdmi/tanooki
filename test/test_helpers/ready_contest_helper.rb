# frozen_string_literal: true

# Builds a preset contest that satisfies every publish-readiness check.
module ReadyContestHelper
  def prepare_ready_contest!
    contest = create_preset_contest
    contest.update!(tagline: 'Слоган', description: 'Тема й підказки для Readiness')
    attach_contest_cover!(contest)
    add_contest_jurors!(contest)
    ::Contests::Readiness.new(contest).mark_previewed!
    contest
  end

  def create_preset_contest
    ::Contests::CreateFromPreset.call(
      preset: 'ranobe',
      submissions_open_at: 5.weeks.from_now.beginning_of_day,
      prize_pool_uah: 3000,
      title: 'Готовий до публікації'
    )
  end

  def attach_contest_cover!(contest)
    path = Rails.root.join('app/assets/images/novel.webp')
    contest.cover.attach(io: File.open(path), filename: 'cover.webp', content_type: 'image/webp')
  end

  def add_contest_jurors!(contest)
    [users(:user_one), users(:user_two), users(:user_one_one_zero)].each_with_index do |user, i|
      contest.jurors.create!(user:, role: i.zero? ? :chair : :member)
    end
  end
end
