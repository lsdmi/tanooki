# frozen_string_literal: true

require 'test_helper'

class FictionFormTagsTest < ActiveSupport::TestCase
  setup do
    @fiction = fictions(:one)
  end

  test 'keeps tag_names from params when save fails' do
    form = FictionForm.new(fiction: @fiction, params: base_params.merge(title: '', tag_names: ['', 'Магія', 'Школа']))

    assert_not form.save
    assert_equal %w[Магія Школа], @fiction.tag_names
  end

  test 'does not treat tag_names as a fiction attribute' do
    form = FictionForm.new(fiction: @fiction, params: base_params.merge(tag_names: ['Магія']))

    assert form.save
    assert_empty @fiction.reload.fiction_tags
  end

  test 'rejects too many tags before saving' do
    names = Array.new(FictionTag::MAX_PER_FICTION + 1) { |index| "Теґ номер #{index}" }
    form = FictionForm.new(fiction: @fiction, params: base_params.merge(title: 'Not Saved', tag_names: names))

    assert_not form.save
    assert_includes @fiction.errors[:tag_names], 'Можна додати не більше 10 теґів.'
  end

  test 'rejected tags leave the fiction row unsaved' do
    names = Array.new(FictionTag::MAX_PER_FICTION + 1) { |index| "Теґ номер #{index}" }
    FictionForm.new(fiction: @fiction, params: base_params.merge(title: 'Not Saved', tag_names: names)).save

    assert_not_equal 'Not Saved', @fiction.reload.title
  end

  test 'rejects an overlong or empty-slug tag name with the name in the message' do
    form = FictionForm.new(fiction: @fiction, params: base_params.merge(tag_names: ['!!!', 'а' * 41]))

    assert_not form.save
    assert_equal ['Теґ «!!!» має містити літери чи цифри.', "Теґ «#{'а' * 41}» задовгий: не більше 40 символів."],
                 @fiction.errors[:tag_names]
  end

  test 'a form without tag_names leaves tag validation alone' do
    assert FictionForm.new(fiction: @fiction, params: base_params).save
    assert_nil @fiction.tag_names
  end

  private

  def base_params
    {
      title: @fiction.title,
      author: @fiction.author,
      description: @fiction.description,
      expected_chapters: @fiction.expected_chapters,
      scanlator_ids: [1]
    }
  end
end
