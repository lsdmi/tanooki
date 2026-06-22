# frozen_string_literal: true

module MorphHeadParityHelpers
  def tracked_stylesheet_hrefs(html)
    html.scan(/<link\b[^>]*data-turbo-track="reload"[^>]*>/).filter_map do |tag|
      tag[/href="([^"]+)"/, 1]
    end.sort
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) { include MorphHeadParityHelpers }
