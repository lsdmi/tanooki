# frozen_string_literal: true

require 'test_helper'

module Reading
  class ResumeLocatorTest < ActiveSupport::TestCase
    DIGEST = 'a' * Chapters::ReaderBlocks::DIGEST_LENGTH

    test 'parses a full locator into progress attributes' do
      locator = ResumeLocator.parse(quote: '  Він   сказав: «Так».  ', block_index: '12', percent: '41.237',
                                    digest: DIGEST)

      assert_equal({ resume_quote: 'Він сказав: «Так».', resume_block_index: 12, resume_percent: 41.24,
                     resume_digest: DIGEST }, locator.attributes)
    end

    test 'truncates the quote to the column length' do
      locator = ResumeLocator.parse(quote: 'я' * 200, percent: 10)

      assert_equal ResumeLocator::QUOTE_LENGTH, locator.quote.length
    end

    test 'no usable percent means no locator' do
      raws = [{ quote: 'text', block_index: 1, digest: DIGEST }, { percent: 'abc' }, { percent: 100.5 },
              { percent: -1 }, nil, 'percent=10']

      parsed = raws.map { ResumeLocator.parse(it) }

      assert_equal [nil] * raws.size, parsed
    end

    test 'drops malformed parts but keeps the percent' do
      locator = ResumeLocator.parse(quote: ['x'], block_index: -3, percent: 50, digest: 'not-a-digest')

      assert_equal({ resume_quote: nil, resume_block_index: nil, resume_percent: 50.0, resume_digest: nil },
                   locator.attributes)
    end

    test 'rejects fractional and huge block indices' do
      assert_nil ResumeLocator.parse(block_index: '1.5', percent: 1).block_index
      assert_nil ResumeLocator.parse(block_index: ResumeLocator::MAX_BLOCK_INDEX + 1, percent: 1).block_index
    end
  end
end
