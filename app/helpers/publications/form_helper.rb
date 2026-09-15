# frozen_string_literal: true

module Publications
  # Publication composer footer and Studio blogs title links.
  module FormHelper
    TITLE_LINK_CLASSES = 'hover:text-cyan-700 dark:hover:text-rose-400 transition-colors duration-200 font-medium'
    MOBILE_TITLE_LINK_CLASSES = "#{TITLE_LINK_CLASSES} block text-gray-900 dark:text-white".freeze

    # Live blogs update the public body on submit; hide Зберегти.
    def show_publication_draft_save?(publication)
      publication.new_record? || publication.draft?
    end

    def publication_studio_title_path(publication)
      publication.draft? ? edit_publication_path(publication) : tale_path(publication)
    end

    def publication_studio_title_html(publication, variant: :desktop)
      css_classes = variant == :mobile ? MOBILE_TITLE_LINK_CLASSES : TITLE_LINK_CLASSES
      if publication.draft?
        { data: { turbo: false }, class: css_classes }
      else
        { data: { turbo_frame: '_top' }, class: css_classes }
      end
    end
  end
end
