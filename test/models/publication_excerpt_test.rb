# frozen_string_literal: true

require 'test_helper'

class PublicationExcerptTest < ActiveSupport::TestCase
  setup do
    @publication = publications(:tale_approved_one)
  end

  test 'saving a new description stores a squished plain-text excerpt' do
    @publication.update!(description: "<p>Перший   абзац.</p><p>#{'Слово ' * 200}</p>")

    excerpt = @publication.reload.excerpt

    assert excerpt.start_with?('Перший абзац. Слово')
    assert_equal Publication::EXCERPT_LENGTH, excerpt.length
    assert excerpt.end_with?('...')
  end

  test 'a save that loads the description refreshes a stale excerpt' do
    publication = Publication.find(@publication.id)
    publication.update!(excerpt: 'Застарілий уривок', views: 5)

    assert_equal Publication.excerpt_from(publication.description), publication.reload.excerpt
  end

  test 'excerpt_from is nil for a blank description' do
    assert_nil Publication.excerpt_from(nil)
    assert_nil Publication.excerpt_from(ActionText::RichText.new(body: ''))
  end
end
