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

  test 'chapters past the preview are hidden once the work is taken down' do
    seventh = @fiction.chapters.find_by(number: 7)
    @fiction.update!(licensed_at: 1.day.ago, license_publisher: 'Видавництво Тест')

    assert_not seventh.reload.license_hidden?

    @fiction.update!(chapters_hidden_at: Time.current)

    assert_predicate seventh.reload, :license_hidden?
    assert_not chapters(:one).reload.license_hidden?
  end

  test 'the takedown state follows what is left to read' do
    @fiction.update!(licensed_at: 1.day.ago, license_publisher: 'Видавництво Тест', chapters_hidden_at: Time.current)

    assert_equal :partial, @fiction.license_chapters_state

    @fiction.chapters.where('number > 6').destroy_all

    assert_equal :open, Fiction.find(@fiction.id).license_chapters_state

    @fiction.chapters.destroy_all

    assert_equal :removed, Fiction.find(@fiction.id).license_chapters_state
  end

  test 'after a takedown even admins list only the preview chapters' do
    @fiction.update!(licensed_at: 1.day.ago, license_publisher: 'Видавництво Тест', chapters_hidden_at: Time.current)

    listed = Library::ChapterCatalog.chapters_scope_for_list(@fiction, users(:user_one)).pluck(:number)

    assert_equal (1..6).to_a, listed.map(&:to_i).sort
  end

  test 'a chapter not yet saved to a fiction is never hidden' do
    assert_not Chapter.new.license_hidden?
  end
end
