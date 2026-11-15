# frozen_string_literal: true

require 'test_helper'

module Chapters
  class ReaderResumeHelperReportTest < ActionView::TestCase
    include ReaderResumeHelper

    setup do
      @chapter = chapters(:one)
      @digest = 'a' * ParagraphReport::DIGEST_LENGTH
    end

    test 'report anchor params become an auto resume locator without percent' do
      stub_params(rp_quote: 'Початок абзацу', rp_i: '3', rp_digest: @digest, resume: '1')

      locator = reader_resume_locator(@chapter)

      assert_equal ['Початок абзацу', 3, nil, @digest, true],
                   [locator.quote, locator.block_index, locator.percent, locator.digest, reader_resume_auto?]
    end

    test 'stale digest is detected against the live chapter' do
      stub_params(rp_digest: @digest)

      assert reader_report_anchor_stale?(@chapter)
    end

    test 'matching digest is not stale' do
      live = Chapters::ReaderContentHtml.new(@chapter).digest
      stub_params(rp_digest: live)

      assert_not reader_report_anchor_stale?(@chapter)
    end

    private

    def stub_params(**values)
      request_params = ActionController::Parameters.new(values)
      define_singleton_method(:params) { request_params }
    end
  end
end
