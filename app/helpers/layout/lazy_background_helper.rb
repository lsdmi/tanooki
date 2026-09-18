# frozen_string_literal: true

module Layout
  # Defers CSS background-image until the section is near the viewport.
  module LazyBackgroundHelper
    def lazy_decoration_background(filename, html_class:, **html)
      {
        class: html_class,
        data: lazy_decoration_background_data(filename),
        **html
      }
    end

    def decoration_small_filename(filename)
      filename.sub(/(\.[A-Za-z0-9]+)\z/, '-sm\1')
    end

    private

    def lazy_decoration_background_data(filename)
      data = {
        controller: 'lazy-bg',
        lazy_bg_observe_value: true,
        lazy_bg_url_value: asset_path(filename)
      }
      small = decoration_small_filename(filename)
      data[:lazy_bg_small_url_value] = asset_path(small) if decoration_asset?(small)
      data
    end

    def decoration_asset?(filename)
      Rails.application.assets.load_path.find(filename).present?
    end
  end
end
