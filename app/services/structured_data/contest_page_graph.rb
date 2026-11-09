# frozen_string_literal: true

module StructuredData
  # Schema.org graph for public contest show: WebPage, breadcrumbs, completed Event, winners.
  module ContestPageGraph
    def contest_page_json(contest)
      contest_page_graph(contest).to_json
    end

    private

    def contest_page_graph(contest)
      seo = Meta::ContestSeo.new(contest)
      page_url = contest_url(contest, only_path: false, **default_public_url_options)
      {
        '@context': 'https://schema.org',
        '@graph': contest_graph_nodes(contest, seo, page_url)
      }
    end

    def contest_graph_nodes(contest, seo, page_url)
      image = contest_cover_image(contest)
      [
        contest_webpage_node(seo, page_url, image),
        contest_breadcrumb_node(contest, page_url),
        contest_event_node(contest, seo, page_url, image),
        contest_winners_node(contest, page_url)
      ].compact
    end

    def contest_webpage_node(seo, page_url, image)
      {
        '@type': 'WebPage',
        '@id': "#{page_url}#webpage",
        name: seo.page_title,
        description: seo.meta_description,
        url: page_url,
        inLanguage: 'uk-UA',
        isPartOf: { '@type' => 'WebSite', name: SiteProfile::NAME, url: public_root_url },
        primaryImageOfPage: image
      }.compact
    end

    def contest_breadcrumb_node(contest, page_url)
      rules = rules_url(anchor: 'contest-rules', only_path: false, **default_public_url_options)
      {
        '@type': 'BreadcrumbList',
        '@id': "#{page_url}#breadcrumb",
        itemListElement: contest_breadcrumb_items(contest, page_url, rules)
      }
    end

    def contest_breadcrumb_items(contest, page_url, rules_url)
      [
        { '@type': 'ListItem', position: 1, name: 'Бака', item: public_root_url },
        { '@type': 'ListItem', position: 2, name: 'Правила конкурсів', item: rules_url },
        { '@type': 'ListItem', position: 3, name: contest.title, item: page_url }
      ]
    end

    def contest_event_node(contest, seo, page_url, image)
      {
        '@type': 'Event', '@id': "#{page_url}#event", name: contest.title,
        description: seo.meta_description, url: page_url, image: [image].compact,
        eventStatus: 'https://schema.org/EventCompleted',
        eventAttendanceMode: 'https://schema.org/OnlineEventAttendanceMode',
        startDate: contest.submissions_open_at&.iso8601,
        endDate: (contest.results_published_at || contest.judging_close_at)&.iso8601,
        organizer: { '@id' => "#{public_root_url}#publisher" },
        location: { '@type': 'VirtualLocation', url: page_url }
      }.compact
    end

    def contest_winners_node(contest, page_url)
      awards = contest_place_awards(contest)
      return if awards.empty?

      {
        '@type': 'ItemList',
        '@id': "#{page_url}#winners",
        name: "Переможці · #{contest.title}",
        numberOfItems: awards.size,
        itemListElement: awards.map.with_index(1) { |award, index| contest_winner_list_item(award, index) }
      }
    end

    def contest_place_awards(contest)
      contest.awards.includes(:contest_prize, contest_entry: :fiction)
             .joins(:contest_prize)
             .merge(ContestPrize.place)
             .order('contest_prizes.place ASC, contest_awards.id ASC')
             .to_a
    end

    def contest_winner_list_item(award, index)
      entry = award.contest_entry
      fiction = entry&.fiction
      {
        '@type': 'ListItem',
        position: award.contest_prize.place || index,
        name: fiction&.title.presence || entry&.display_title,
        item: contest_winner_item_url(fiction, entry)
      }.compact
    end

    def contest_winner_item_url(fiction, entry)
      return fiction_url(fiction, only_path: false, **default_public_url_options) if fiction

      entry&.legacy_url.presence
    end

    def contest_cover_image(contest)
      return unless contest.cover.attached?

      rails_blob_url(contest.cover, only_path: false, **default_public_url_options)
    end
  end
end
