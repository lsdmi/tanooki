# frozen_string_literal: true

require 'test_helper'

module Publications
  class FormHelperTest < ActionView::TestCase
    include FormHelper

    test 'show_publication_draft_save? is true for new records' do
      assert show_publication_draft_save?(Publication.new)
    end

    test 'show_publication_draft_save? is true for drafts' do
      publication = publications(:tale_approved_one)
      publication.status = :draft

      assert show_publication_draft_save?(publication)
    end

    test 'show_publication_draft_save? is false for published publications' do
      assert_not show_publication_draft_save?(publications(:tale_approved_one))
    end

    test 'publication_studio_title_path points drafts at edit' do
      publication = publications(:tale_approved_one)
      publication.status = :draft

      assert_equal edit_publication_path(publication), publication_studio_title_path(publication)
    end

    test 'publication_studio_title_path points published blogs at tale' do
      publication = publications(:tale_approved_one)

      assert_equal tale_path(publication), publication_studio_title_path(publication)
    end
  end
end
