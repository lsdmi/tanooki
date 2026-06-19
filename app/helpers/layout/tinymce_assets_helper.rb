# frozen_string_literal: true

module Layout
  # Propshaft-compatible TinyMCE script tags.
  #
  # tinymce-rails' default `tinymce_assets` helper loads `tinymce.js`, which is a
  # Sprockets bundle (`//= require ...`). Propshaft serves that file verbatim, so the
  # library never loads. We include preinit + the vendor library explicitly instead.
  module TinymceAssetsHelper
    def tinymce_script_tags
      safe_join(
        [
          tinymce_preinit_script,
          javascript_include_tag('tinymce/tinymce')
        ],
        "\n"
      )
    end

    private

    def tinymce_preinit_script
      # Pass a string (not a block): javascript_tag block content is HTML-escaped (&#39; breaks JS).
      script = "window.tinymce = window.tinymce || { base: #{TinyMCE::Rails::Engine.base.to_json}, suffix: '' };"
      javascript_tag(script, nonce: true)
    end
  end
end
