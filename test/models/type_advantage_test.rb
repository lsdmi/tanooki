# frozen_string_literal: true

require 'test_helper'

class TypeAdvantageTest < ActiveSupport::TestCase
  test 'loading type advantages from YAML file' do
    assert_kind_of Hash, TypeAdvantage.load
  end

  test 'calculating effectiveness for valid types' do
    assert_equal 1.25, TypeAdvantage.effectiveness('Вогняний', "Трав'яний")
    assert_equal 1.25, TypeAdvantage.effectiveness('Водяний', 'Вогняний')
    assert_equal 1.25, TypeAdvantage.effectiveness("Трав'яний", 'Водяний')
  end
end
