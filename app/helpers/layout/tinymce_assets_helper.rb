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
      javascript_tag(nonce: true) do
        <<~JS
          window.tinymce = window.tinymce || {
            base: '#{j TinyMCE::Rails::Engine.base}',
            suffix: ''
          };
        JS
      end
    end
  end
end
