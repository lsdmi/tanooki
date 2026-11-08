# frozen_string_literal: true

module Contests
  # Data tables for the contest page: actions per phase and role (8.4), sections and their order (8.3).
  module ShowMatrix
    GALLERY_PHASES = %i[submissions judging awaiting_results results].freeze

    # Action registry: target resolves to an href in ShowPresenter; kind tells the view how to render it.
    ACTIONS = {
      read_rules: { target: :rules, kind: :anchor },
      follow_telegram: { target: :telegram, kind: :external },
      join: { target: :join, kind: :path },
      my_participation: { target: :my_entry, kind: :anchor },
      add_chapter: { target: :add_chapter, kind: :path },
      read_works: { target: :works, kind: :anchor },
      read_winners: { target: :results, kind: :anchor },
      my_result: { target: :my_entry, kind: :anchor },
      cancellation_info: { target: :cancellation, kind: :anchor },
      my_work_after_cancel: { target: :my_entry, kind: :anchor },
      edit_contest: { target: :admin_edit, kind: :path },
      review_entries: { target: :admin_entries, kind: :path },
      jury_scores: { target: :admin_show, kind: :path }
    }.freeze

    # phase => role => [primary, secondary]. awaiting_results reuses judging.
    MATRIX = {
      announced: {
        guest: %i[read_rules follow_telegram],
        reader: %i[read_rules follow_telegram],
        participant: %i[read_rules follow_telegram],
        admin: %i[edit_contest read_rules]
      },
      submissions: {
        guest: %i[join read_rules],
        reader: %i[join read_rules],
        participant: %i[my_participation add_chapter],
        admin: %i[review_entries read_rules]
      },
      judging: {
        guest: %i[read_works],
        reader: %i[read_works],
        participant: %i[my_participation],
        admin: %i[jury_scores]
      },
      results: {
        guest: %i[read_winners],
        reader: %i[read_winners],
        participant: %i[my_result],
        admin: []
      },
      cancelled: {
        guest: %i[cancellation_info],
        reader: %i[cancellation_info],
        participant: %i[my_work_after_cancel],
        admin: []
      }
    }.freeze

    # Sections in default order. Optional keys: phases, roles, if (presenter predicate), nav (nav label key).
    SECTIONS = [
      { id: :hero, anchor: 'hero', component: 'Contests::HeroComponent' },
      { id: :cancellation, anchor: 'cancelled', partial: 'contests/cancellation', phases: %i[cancelled] },
      { id: :summary, anchor: 'summary', component: 'Contests::SummaryComponent',
        phases: Phase::ACTIVE_PHASES + %i[cancelled] },
      { id: :section_nav, anchor: 'sections', component: 'Contests::SectionNavComponent',
        phases: Phase::ACTIVE_PHASES + %i[cancelled] },
      { id: :results, anchor: 'results', partial: 'contests/results', phases: %i[results] },
      { id: :my_participation, anchor: 'my-entry', partial: 'contests/my_participation',
        phases: %i[submissions judging awaiting_results], roles: %i[participant admin], if: :my_entry },
      { id: :how_to_join, anchor: 'how-to-join', partial: 'contests/how_to_join',
        phases: %i[announced submissions], nav: 'how_to_join' },
      { id: :board, anchor: 'about', partial: 'contests/theme',
        nav_links: [{ nav: 'about', anchor: 'about' }, { nav: 'prizes', anchor: 'prizes' }] },
      { id: :requirements, anchor: 'requirements', partial: 'contests/requirements',
        phases: Phase::ACTIVE_PHASES + %i[cancelled] },
      { id: :works, anchor: 'works', partial: 'contests/works', phases: GALLERY_PHASES, nav: 'works' },
      { id: :closing, anchor: 'discussion', partial: 'contests/closing',
        nav_links: [{ nav: 'discussion', anchor: 'discussion' }, { nav: 'rules', anchor: 'rules' }] }
    ].freeze

    # Sections pinned right after the hero (in this order) for a phase; the rest keep default order.
    LEAD_SECTIONS = {
      results: %i[hero results],
      cancelled: %i[hero cancellation]
    }.freeze
  end
end
