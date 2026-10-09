# frozen_string_literal: true

require 'test_helper'

class FictionLicenseTakedownTest < ActiveSupport::TestCase
  setup do
    @fiction = fictions(:one)
    @fiction.scanlator_ids = @fiction.scanlators.ids
    (3..8).each do |number|
      Chapter.create!(fiction: @fiction, user: users(:user_one), title: "Chapter #{number}", number:,
                      content: 'x' * 500, scanlator_ids: [scanlators(:one).id])
    end
  end

  test 'only a licensed work can hide its chapters' do
    @fiction.chapters_hidden_at = Time.current

    assert_not @fiction.valid?
    assert_includes @fiction.errors.details[:chapters_hidden_at], { error: :present }
  end

  test 'marking hides chapters past the preview and the admin takedown hides the rest' do
    seventh = @fiction.chapters.find_by(number: 7)
    license!

    assert_predicate seventh.reload, :license_hidden?
    assert_not chapters(:one).reload.license_hidden?

    @fiction.update!(chapters_hidden_at: Time.current)

    assert_predicate chapters(:one).reload, :license_hidden?
  end

  test 'the state follows what is left to read' do
    license!

    assert_equal :partial, @fiction.license_chapters_state

    @fiction.chapters.where('number > 6').destroy_all

    assert_equal :open, Fiction.find(@fiction.id).license_chapters_state

    @fiction.update!(chapters_hidden_at: Time.current)

    assert_equal :removed, Fiction.find(@fiction.id).license_chapters_state
  end

  test 'a licensed work lists only the preview for everyone, and nothing after the takedown' do
    license!
    admin = users(:user_one)

    listed = Library::ChapterCatalog.chapters_scope_for_list(@fiction, admin).pluck(:number)

    assert_equal (1..6).to_a, listed.map(&:to_i).sort

    @fiction.update!(chapters_hidden_at: Time.current)

    assert_empty Library::ChapterCatalog.chapters_scope_for_list(Fiction.find(@fiction.id), admin)
  end

  test 'an unlicensed work lists every chapter' do
    assert_equal 8, Library::ChapterCatalog.chapters_scope_for_list(@fiction, nil).count
    assert_equal :open, @fiction.license_chapters_state
  end

  test 'a licensed work keeps EPUB off for the preview too' do
    license!

    assert_not Books::EpubDownloadPermission.allowed?([chapters(:one)])
  end

  test 'a chapter not yet saved to a fiction is never hidden' do
    assert_not Chapter.new.license_hidden?
  end

  private

  def license!
    @fiction.update!(licensed_at: 1.day.ago, license_publisher: 'Видавництво Тест')
  end
end
