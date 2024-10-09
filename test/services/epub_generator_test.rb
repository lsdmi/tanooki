# frozen_string_literal: true

require 'test_helper'

class EpubGeneratorTest < ActiveSupport::TestCase
  def setup
    @rich_text_ids = [3]
    @volume_title = 'Volume 1'
    @epub_generator = EpubGenerator.new(@rich_text_ids, @volume_title)
  end

  test 'should initialize with correct attributes' do
    assert_equal @rich_text_ids, @epub_generator.instance_variable_get(:@rich_texts).pluck(:id)
    assert_equal @volume_title, @epub_generator.instance_variable_get(:@volume_title)
    assert_not_nil @epub_generator.file_path
  end

  test 'should generate epub file' do
    @epub_generator.generate
    assert File.exist?(@epub_generator.file_path)
  end
end
