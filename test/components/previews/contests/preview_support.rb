# frozen_string_literal: true

module Contests
  # Shared Lookbook stubs so previews render without a seeded contest.
  module PreviewSupport
    unless const_defined?(:FakePrize, false)
      FakePrize = Struct.new(:title, :cash_uah, :perks, :unlock_at_uah, :position, :id, :place, :kind,
                             keyword_init: true)

      class FakePrizes < Array
        def order(*) = self
        def place = self.class.new(select { |prize| prize.kind == 'place' || prize.place.present? })
        def where(*) = self
      end

      FakeContest = Struct.new(
        :title, :tagline, :kind, :phase, :slug, :cover, :submissions_close_at, :submissions_open_at,
        :prize_pool_uah, :donations_uah, :carryover_uah, :donation_url, :prizes, :criteria, :jury_weight,
        :requires_new_work, :min_chapters, :min_words, :max_content_rating, :required_genre,
        keyword_init: true
      ) do
        def requires_new_work? = requires_new_work
      end

      class FakePresenter
        attr_reader :contest, :phase

        def initialize(contest:, phase: :submissions)
          @contest = contest
          @phase = phase
        end

        def primary_action
          {
            label_key: 'contests.show.actions.join',
            label_args: {},
            href: '#join',
            kind: :path
          }
        end

        def secondary_action
          {
            label_key: 'contests.show.actions.read_rules',
            label_args: {},
            href: '#rules',
            kind: :anchor
          }
        end

        def summary_facts
          [
            { key: :deadline, label: 'Дедлайн', value: I18n.l(contest.submissions_close_at.to_date) },
            { key: :fee, label: 'Внесок', value: 'безкоштовно' },
            { key: :first_prize, label: 'Перший приз', value: '1 500 ₴ (фонд 3 750 ₴)' },
            { key: :who, label: 'Хто може', value: 'зареєстровані з підтвердженою поштою' },
            { key: :what, label: 'Що подавати', value: 'новий ориджинал · від 10 000 слів · не менше 3 розділів' },
            { key: :genre_rating, label: 'Жанр і маркування', value: 'до 16+' }
          ]
        end

        def nav_items
          [
            { id: :theme, anchor: 'about', label_key: 'contests.show.nav.about' },
            { id: :prizes, anchor: 'prizes', label_key: 'contests.show.nav.prizes' },
            { id: :works, anchor: 'works', label_key: 'contests.show.nav.works' },
            { id: :rules, anchor: 'rules', label_key: 'contests.show.nav.rules' }
          ]
        end

        def timeline_steps
          now = Time.zone.now
          [
            { key: :announced, at: now - 4.weeks, current: phase == :announced },
            { key: :submissions, at: now - 2.weeks, current: phase == :submissions },
            { key: :judging, at: now + 4.weeks, current: phase == :judging },
            { key: :awaiting_results, at: now + 7.weeks, current: phase == :awaiting_results },
            { key: :results, at: nil, current: phase == :results }
          ]
        end

        def prize_pool_total
          contest.prize_pool_uah + contest.donations_uah + contest.carryover_uah
        end

        def donation_goals
          contest.prizes.select { |prize| prize.unlock_at_uah.present? }
        end
      end
    end

    module_function

    def sample_prizes
      FakePrizes.new([
                       FakePrize.new(id: 1, title: '1 місце', cash_uah: 1500, perks: 'бейдж, промо',
                                     unlock_at_uah: nil, position: 0, place: 1, kind: 'place'),
                       FakePrize.new(id: 2, title: 'Номінація за атмосферу', cash_uah: 500, perks: 'бейдж',
                                     unlock_at_uah: 4000, position: 1, place: nil, kind: 'nomination')
                     ])
    end

    def sample_contest_copy
      {
        title: 'Поріг',
        tagline: 'Напиши історію про крок, після якого немає вороття',
        kind: 'original',
        slug: 'porih',
        cover: nil,
        donation_url: 'https://example.com/donate'
      }
    end

    def sample_contest_money
      {
        submissions_close_at: 6.weeks.from_now,
        submissions_open_at: 2.weeks.ago,
        prize_pool_uah: 3000,
        donations_uah: 750,
        carryover_uah: 0
      }
    end

    def sample_contest_rules
      {
        criteria: Contest::DEFAULT_CRITERIA,
        jury_weight: 60,
        requires_new_work: true,
        min_chapters: 3,
        min_words: 10_000,
        max_content_rating: 16,
        required_genre: nil
      }
    end

    def sample_contest(phase: :submissions)
      FakeContest.new(
        phase:, prizes: sample_prizes,
        **sample_contest_copy, **sample_contest_money, **sample_contest_rules
      )
    end

    def sample_presenter(phase: :submissions)
      FakePresenter.new(contest: sample_contest(phase:), phase:)
    end
  end
end
